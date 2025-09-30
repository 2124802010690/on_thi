// lib/services/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';


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
    // Đảm bảo thư mục databases tồn tại
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Load file DB từ assets
    ByteData data = await rootBundle.load("assets/db/onthi.db");
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Ghi ra file onthi.db trong thiết bị
    await File(path).writeAsBytes(bytes, flush: true);
  }

  // Mở DB và trả về
  return await openDatabase(
  path,
  version: 1,
  onConfigure: (db) async {
    await db.execute("PRAGMA foreign_keys = ON");
  },
);

}

  // Thêm email vào registerUser
  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;
    try {
      final id = await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
      });
      return id;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return -1; // Email hoặc tên đăng nhập đã tồn tại
      }
      rethrow;
    }
  }



    // Phương thức đăng nhập
  Future<Map<String, dynamic>?> login(String name, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'name = ? AND password = ?',
      whereArgs: [name, password],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (users.isNotEmpty) {
      // Logic đã được sửa đổi: Trả về toàn bộ thông tin người dùng từ cơ sở dữ liệu
      return users.first;
    }
    return null;
  }
  
  // Thêm hàm cập nhật thông tin người dùng vào cơ sở dữ liệu
  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }
  // Phương thức này sẽ lấy TẤT CẢ các câu hỏi từ bảng 'questions'

  Future<List<Question>> getAllQuestions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('questions');
    
    return List.generate(maps.length, (i) {
      return Question.fromMap(maps[i]);
    });
  }

  /// Lấy user theo id
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

// đổi mật khẩu trong ChangePasswordScreen
 /// Cập nhật mật khẩu (kiểm tra mật khẩu cũ trước khi update)
  Future<int> updatePassword(int userId, String oldPass, String newPass) async {
    final db = await database;

    // kiểm tra user và mật khẩu cũ
    final user = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, oldPass],
    );

    if (user.isEmpty) {
      // mật khẩu cũ không đúng
      return 0;
    }

    // cập nhật mật khẩu mới
    return await db.update(
      'users',
      {'password': newPass},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

/*
  // Phương thức onUpgrade để thêm cột answers
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE results ADD COLUMN answers TEXT');
    }
  }
*/


  // ---------------- CRUD Methods ----------------

  // Lấy danh sách Topics
  Future<List<Map<String, dynamic>>> getTopics() async {
    final db = await database;
    return await db.query('topics', orderBy: 'pos');
  }

  // Lấy câu hỏi theo Topic
  Future<List<Map<String, dynamic>>> getQuestionsByTopicId(int topicId) async {
    final db = await database;
    return await db.query(
      'questions',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'pos',
    );
  }

Future<List<Map<String, dynamic>>> getExamQuestions() async {
  final db = await database;
  List<Map<String, dynamic>> exam = [];
  final int totalQuestionsNeeded = 30; // Tổng số câu hỏi cần có

  // Lấy tất cả các chủ đề
  final topics = await db.query('topics', orderBy: 'pos');
  if (topics.isEmpty) return [];

  // 1. Lấy một số câu hỏi cơ sở từ mỗi chủ đề
  int baseCountPerTopic = 5; // Bắt đầu với 5 câu hỏi mỗi chủ đề
  
  for (var topic in topics) {
    final topicId = topic['id'] as int;
    final qs = await db.query(
      'questions',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'RANDOM()', // Lấy ngẫu nhiên
      limit: baseCountPerTopic,
    );
    exam.addAll(qs);
  }

  // 2. Kiểm tra xem cần bổ sung bao nhiêu câu nữa
  int questionsNeeded = totalQuestionsNeeded - exam.length;

  // 3. Nếu thiếu, lấy thêm các câu hỏi ngẫu nhiên từ toàn bộ kho
  if (questionsNeeded > 0) {
    final remainingQuestions = await db.query(
      'questions',
      where: 'id NOT IN (${exam.map((q) => q['id']).join(',')})', // Loại trừ các câu đã có
      orderBy: 'RANDOM()',
      limit: questionsNeeded,
    );
    exam.addAll(remainingQuestions);
  }

  // 4. Trộn ngẫu nhiên danh sách cuối cùng để các câu hỏi không bị theo thứ tự chủ đề
  exam.shuffle();

  return exam;
}
  // Thêm kết quả thi
  Future<int> insertResult(Map<String, dynamic> result) async {
    final db = await database;
    return await db.insert('results', result);
  }
  // Lấy danh sách kết quả bài thi của người dùng
  Future<List<Map<String, dynamic>>> getResultsByUserId(int userId) async {
    final db = await database; // Đảm bảo bạn đã khởi tạo database ở đây
    return await db.query(
      'results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'taken_at DESC', // Sắp xếp theo thời gian mới nhất
    );
  }
}