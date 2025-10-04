import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert'; // ⭐ Thêm import này cho json.decode

import '../models/question.dart';
import '../models/user_model.dart';
import '../models/result_model.dart';
import '../models/topic.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'onthi.db');

    // Nếu DB chưa tồn tại thì copy từ assets
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load("assets/db/onthi.db");
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

  // ---------------- USER METHODS ----------------

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUser(String email, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  /// Đăng ký user (return id hoặc -1 nếu email đã tồn tại)
  Future<int> registerUser(UserModel user) async {
    final db = await database;
    try {
      final id = await db.insert('users', user.toMap());
      return id;
    } on DatabaseException catch (e) {
      // isUniqueConstraintError() là hàm mở rộng trong sqflite
      // nếu bạn không dùng nó, hãy kiểm tra lỗi theo cách khác
      // if (e.isUniqueConstraintError()) { 
      //   return -1; // Email đã tồn tại
      // }
      rethrow;
    }
  }

  /// Đăng nhập bằng email + password
  Future<UserModel?> loginUser(String email, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  /// Lấy user theo id
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  /// Cập nhật user
  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Đổi mật khẩu (check oldPass trước)
  Future<int> updatePassword(int userId, String oldPass, String newPass) async {
    final db = await database;

    final user = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, oldPass],
    );

    if (user.isEmpty) {
      return 0; // mật khẩu cũ không đúng
    }

    return await db.update(
      'users',
      {'password': newPass},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ---------------- QUESTION METHODS ----------------

  /// Lấy tất cả câu hỏi
  Future<List<Question>> getAllQuestions() async {
    final db = await database;
    final maps = await db.query('questions');
    return maps.map((q) => Question.fromMap(q)).toList();
  }

  /// Lấy danh sách chủ đề
  Future<List<Topic>> getTopics() async {
    final db = await database;
    final maps = await db.query('topics');

    return maps.map((map) => Topic.fromMap(map)).toList();
  }

  /// Lấy câu hỏi theo topic
  Future<List<Question>> getQuestionsByTopicId(int topicId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'pos',
    );
    return maps.map((q) => Question.fromMap(q)).toList();
  }

  /// Lấy 30 câu hỏi ngẫu nhiên (phân bổ theo topic)
  Future<List<Question>> getExamQuestions() async {
    final db = await database;
    List<Question> exam = [];
    const int totalQuestionsNeeded = 35;

    final topics = await db.query('topics', orderBy: 'pos');
    if (topics.isEmpty) return [];

    // Lấy 5 câu/topic cho 6 topic
    int baseCountPerTopic = 5;

    for (var topic in topics) {
      final topicId = topic['id'] as int;
      final qs = await db.query(
        'questions',
        where: 'topic_id = ?',
        whereArgs: [topicId],
        orderBy: 'RANDOM()',
        limit: baseCountPerTopic,
      );
      exam.addAll(qs.map((q) => Question.fromMap(q)));
    }

    int questionsNeeded = totalQuestionsNeeded - exam.length;

    if (questionsNeeded > 0) {
      final ids = exam.map((q) => q.id).join(',');
      final remainingQuestions = await db.query(
        'questions',
        where: ids.isNotEmpty ? 'id NOT IN ($ids)' : null,
        orderBy: 'RANDOM()',
        limit: questionsNeeded,
      );
      exam.addAll(remainingQuestions.map((q) => Question.fromMap(q)));
    }

    exam.shuffle();
    return exam;
  }

  // ---------------- HELPER METHOD: PASS/FAIL LOGIC ----------------

  /// ⭐ HÀM TÍNH TOÁN TRẠNG THÁI ĐẠT/TRƯỢT CHÍNH XÁC ⭐
  int _checkIfPassed(
      int score, Map<int, String> userAnswers, List<Question> examQuestions) {
    const int PASSING_SCORE_MIN = 33; // Ngưỡng đỗ tối thiểu cho B1/B2/C

    // 1. Kiểm tra điểm số
    if (score < PASSING_SCORE_MIN) {
      return 0; 
    }

    // 2. Kiểm tra câu điểm liệt
    for (var question in examQuestions) {
      // Giả định Question Model có thuộc tính 'mandatory' (1 hoặc 0)
      if (question.mandatory == 1) { 
        final userAnswer = userAnswers[question.id];
        
        // userAnswers chứa câu trả lời của người dùng.
        // question.ansright là đáp án đúng từ DB.
        if (userAnswer != null && userAnswer.isNotEmpty && userAnswer != question.ansright) {
          return 0; // TRƯỢT do sai câu điểm liệt
        }
      }
    }

    return 1; // ĐẠT
  }

  // ---------------- RESULT METHODS ----------------

  /// ⭐ CẬP NHẬT HÀM insertResult ĐỂ TÍNH TOÁN LẠI 'PASSED' ⭐
  Future<int> insertResult(ResultModel result) async {
    final db = await database;

    // --- 1. CHUẨN BỊ DỮ LIỆU ĐỂ TÍNH TOÁN ---
    
    // a. Lấy danh sách ID câu hỏi đã thi
    final List<int> questionIds = result.questionIds!
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    // b. Lấy Question models từ DB dựa trên IDs
    final String idsIn = questionIds.join(',');
    final List<Map<String, dynamic>> questionMaps = await db.query(
      'questions',
      where: 'id IN ($idsIn)',
    );
    final List<Question> examQuestions =
        questionMaps.map((q) => Question.fromMap(q)).toList();

    // c. Parse đáp án người dùng (answers là String JSON)
    final dynamic decodedDynamic = json.decode(result.answers!);
    // Chuyển Map<String, dynamic> thành Map<int, String>
    final Map<int, String> userAnswers = (decodedDynamic is Map
            ? Map<String, dynamic>.from(decodedDynamic)
            : <String, dynamic>{})
        .map((key, value) =>
            MapEntry(int.tryParse(key.toString()) ?? -1, value.toString()))
        ..removeWhere((k, v) => k == -1);

    // --- 2. TÍNH TOÁN PASSED CHÍNH XÁC ---
    final int calculatedPassed =
        _checkIfPassed(result.score, userAnswers, examQuestions);

    // --- 3. TẠO RESULT MODEL VỚI GIÁ TRỊ PASSED ĐÃ SỬA VÀ THỰC HIỆN INSERT ---
    final Map<String, dynamic> correctedResultMap = result.toMap();
    correctedResultMap['passed'] = calculatedPassed; // ⭐ Ghi đè giá trị 'passed'

    return await db.insert('results', correctedResultMap);
  }

  Future<List<ResultModel>> getResultsByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'taken_at DESC',
    );
    return maps.map((r) => ResultModel.fromMap(r)).toList();
  }
}