// lib/services/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart'; // Add this line

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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

  
  Future _onCreate(Database db, int version) async {
    // Bảng Topics
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title VARCHAR(128),
        description TEXT,
        featureimg TEXT,
        parent INTEGER,
        pos INTEGER,
        status VARCHAR(16)
      )
    ''');

    // Bảng Questions
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title VARCHAR(64),
        content VARCHAR(512),
        image TEXT,  
        audio VARCHAR(128),
        ansa VARCHAR(512),
        ansb VARCHAR(512),
        ansc VARCHAR(512),
        ansd VARCHAR(512),
        ansright VARCHAR(1),
        anshint TEXT,
        topic_id INTEGER,
        mandatory INTEGER DEFAULT 0,
        pos INTEGER,
        status VARCHAR(16),
        FOREIGN KEY(topic_id) REFERENCES topics(id)
      )
    ''');

    // Bảng Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    // Bảng Results
    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        score INTEGER,
        total INTEGER,
        passed INTEGER,
        failed_due_mandatory INTEGER,
        taken_at TEXT,
        answers TEXT 
      )
    ''');

    // ---------------- Demo data ----------------

    // Demo Topics
    await db.insert('topics', {
      'id': 1,
      'title': 'Chương 1 - Quy định chung và quy tắc giao thông đường bộ',
      'description': 'Các quy định pháp luật về an toàn giao thông đường bộ',
      'pos': 1,
      'status': 'active'
    });
    await db.insert('topics', {
      'id': 2,
      'title': 'Chương 2 - Văn hóa giao thông, đạo đức người lái xe, kỹ năng phòng cháy, chữa cháy và cứu hộ cứu nạn',
      'description': 'Văn hóa giao thông',
      'pos': 2,
      'status': 'active'
    });

    await db.insert('topics', {
      'id': 3,
      'title': 'Chương 3 - Kỹ thuật lái xe',
      'description': 'Kỹ thuật lái xe',
      'pos': 3,
      'status': 'active'
    });

    await db.insert('topics', {
      'id': 4,
      'title': 'Chương 4 - Cấu tạo và sửa chữa',
      'description': 'Cấu tạo và sửa chữa',
      'pos': 4,
      'status': 'active'
    });

    await db.insert('topics', {
      'id': 6,
      'title': 'Chương 6 - Giải thể sa hình và kỹ năng xử lý tình huống giao thông ',
      'description': 'Giải thể sa hình và kỹ năng xử lý tình huống giao thông',
      'pos': 6,
      'status': 'active'
    });

    // Demo Questions
    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 1 - 111',
      'content': 'Những trường hợp nào dưới đây không được đi trên đường cao tốc, trừ người, phương tiện giao thông đường bộ và thiết bị phục vụ việc quản lý, bảo trì đường cao tốc?',
      'ansa': 'Xe máy chuyên dùng có tốc độ thiết kế nhỏ hơn tốc độ tối thiểu quy định đối với đường cao tốc, xe chở người bốn bánh có gắn động cơ, xe chở hàng bốn bánh có gắn động cơ, xe mô tô, xe gắn máy, các loại xe tương tự xe mô tô, xe gắn máy, xe thô sơ, người đi bộ.',
      'ansb': 'Xe máy chuyên dùng có tốc độ thiết kế lớn hơn tốc độ tối thiểu quy định đối với đường cao tốc.',
      'ansc': 'Xe ô tô và xe máy chuyên dùng có tốc độ thiết kế lớn hơn 80 km/h.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 2 - 112',
      'content': 'Khi tham gia giao thông trên đường cao tốc, xe ưu tiên đi làm nhiệm vụ khẩn cấp được đi ngược chiều trong trường hợp nào dưới đây?',
      'ansa': 'Được đi ngược chiều bất cứ làn đường nào của đường cao tốc có thể đi được.',
      'ansb': 'Chỉ được đi ngược chiều trên làn dừng xe khẩn cấp.',
      'ansc': 'Chỉ được đi ngược chiều trên làn đường sát dải phân cách của đường cao tốc.',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 3 - 113',
      'content': 'Khi tham gia giao thông trên đường cao tốc, người lái xe không được thực hiện hành vi nào sau đây?',
      'ansa': 'Dừng, đỗ xe trên phần đường xe chạy, trừ trường hợp xe không thể di chuyển được vào làn đường khẩn cấp',
      'ansb': 'Lùi xe, quay đầu xe. ',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 4 - 114',
      'content': 'Khi xe gặp sự cố kỹ thuật trên đường cao tốc, bạn phải xử lý như thế nào để bảo đảm an toàn giao thông? ',
      'ansa': 'Bật đèn tín hiệu khẩn cấp, dừng xe ngay lập tức và đặt biển báo hiệu nguy hiểm để cảnh báo cho các xe khác. ',
      'ansb': 'Bật tín hiệu khẩn cấp, lập tức đưa xe vào làn đường xe chạy bên phải trong cùng, đặt biển báo hiệu nguy hiểm để cảnh báo cho các xe khác.',
      'ansc': 'Dừng xe, đỗ xe ở làn dừng khẩn cấp cùng chiều xe chạy và phải có báo hiệu bằng đèn khẩn cấp; trường hợp xe không thể di chuyển được vào làn dừng khẩn cấp, phải có báo hiệu bằng đèn khẩn cấp và đặt biển hoặc đèn cảnh báo về phía sau xe khoảng cách tối thiểu 150 mét, nhanh chóng báo cho cơ quan Cảnh sát giao thông thực hiện nhiệm vụ bảo đảm trật tự, an toàn giao thông trên tuyến hoặc cơ quan quản lý đường cao tốc. ',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 5 - 115',
      'content': 'Trên đường cao tốc, người lái xe xử lý như thế nào khi đã vượt quá lối ra của đường định rẽ? ',
      'ansa': 'Quay đầu xe, chạy trên lề đường có lối ra và rẽ khỏi đường cao tốc. ',
      'ansb': 'Lùi xe trên lề đường có lối ra và rẽ khỏi đường cao tốc. ',
      'ansc': 'Tiếp tục lái xe và rẽ ở lối ra tiếp theo. ',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 6 - 116',
      'content': 'Khi xảy ra ùn tắc trên đường cao tốc có làn dừng xe khẩn cấp, người lái xe có được cho xe chạy ở làn dừng xe khẩn cấp để nhanh chóng thoát khỏi khu vực ùn tắc không (trừ xe ưu tiên)? ',
      'ansa': 'Có',
      'ansb': 'Không',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 7 - 117',
      'content': 'Khi chuẩn bị nhập vào làn đường của đường cao tốc, người lái xe, người điều khiển xe máy chuyên dùng phải thực hiện như thế nào là đúng quy tắc giao thông? ',
      'ansa': 'Có tín hiệu xin vào và phải nhường đường cho xe đang chạy trên đường.',
      'ansb': 'Quan sát xe phía sau bảo đảm khoảng cách an toàn mới cho xe nhập vào làn đường sát bên phải.',
      'ansc': 'Nếu có làn đường tăng tốc thì phải cho xe chạy trên làn đường đó trước khi nhập vào làn đường của đường cao tốc.',
      'ansd': 'Cả ba ý trên.',
      'ansright': 'D',
      'mandatory': 1,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 8 - 118',
      'content': 'Theo quy định về độ tuổi, người đủ bao nhiêu tuổi trở lên thì được cấp giấy phép lái xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế trên 3.500 kg đến 7.500 kg; các loại xe ô tô tải quy định cho giấy phép lái xe hạng C1 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg? ',
      'ansa': '18 tuổi',
      'ansb': '17 tuổi',
      'ansc': '16 tuổi',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 9 - 119',
      'content': 'Theo quy định về độ tuổi, người đủ bao nhiêu tuổi trở lên thì được cấp giấy phép lái xe mô tô hai bánh có dung tích xi lanh đến 125 cm3 và xe ô tô chở người đến 8 chỗ (không kể chỗ của người lái xe); xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế đến 3.500 kg? ',
      'ansa': '16 tuổi',
      'ansb': '17 tuổi',
      'ansc': '18 tuổi',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 10 - 120',
      'content': 'Theo quy định về độ tuổi, người lái xe ô tô chở người (kể cả xe buýt) trên 29 chỗ (không kể chỗ của người lái xe); xe ô tô chở người giường nằm; các loại xe ô tô chở người quy định cho giấy phép lái xe hạng D kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg phải đủ bao nhiêu tuổi trở lên?',
      'ansa': '23 tuổi',
      'ansb': '24 tuổi',
      'ansc': '27 tuổi',
      'ansd': '30 tuổi',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 11 - 121',
      'content': 'Tuổi tối đa của người lái xe ô tô chở người (kể cả xe buýt) trên 29 chỗ (không kể chỗ của người lái xe), xe ô tô chở người giường nằm là bao nhiêu tuổi?  ',
      'ansa': 'Đủ 55 tuổi đối với nam và đủ 50 tuổi đối với nữ.',
      'ansb': 'Đủ 55 tuổi đối với nam và nữ.',
      'ansc': 'Đủ 57 tuổi đối với nam và đủ 55 tuổi đối với nữ.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 12 - 122',
      'content': 'Theo quy định về độ tuổi, người lái xe ô tô chở người (kể cả xe buýt) trên 16 chỗ (không kể chỗ của người lái xe) đến 29 chỗ (không kể chỗ của người lái xe); các loại xe ô tô chở người quy định cho giấy phép lái xe hạng D2 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg phải đủ bao nhiêu tuổi trở lên? ',
      'ansa': '23 tuổi',
      'ansb': '24 tuổi',
      'ansc': '22 tuổi',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 13 - 123',
      'content': 'Người đủ 16 tuổi đến dưới 18 tuổi chỉ được điều khiển các loại xe nào dưới đây? ',
      'ansa': 'Xe mô tô hai bánh có dung tích xi-lanh đến 125 cm3 .',
      'ansb': 'Xe gắn máy.',
      'ansc': 'Xe ô tô chở người đến 08 chỗ (không kể chỗ của người lái xe); xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế đến 3.500 kg; các loại xe ô tô quy định cho giấy phép lái xe hạng B kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansd': 'Cả 3 ý trên.',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 14 - 124',
      'content': 'Người có Giấy phép lái xe mô tô hạng A1 không được phép điều khiển loại xe nào dưới đây? ',
      'ansa': 'Xe mô tô hai bánh có dung tích xi-lanh 125 cm3 hoặc có công suất động cơ điện đến 11 kW.',
      'ansb': 'Xe mô tô ba bánh.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 15 - 125',
      'content': 'Người có Giấy phép lái xe mô tô hạng A1 được cấp sau ngày 01/01/2025 được phép điều khiển loại xe nào dưới đây? ',
      'ansa': 'Xe mô tô hai bánh có dung tích xi-lanh đến 125 cm3 hoặc có công suất động cơ điện đến 11 kW.',
      'ansb': 'Xe mô tô ba bánh.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 16 - 126',
      'content': 'Người có Giấy phép lái xe mô tô hạng A được phép điều khiển loại xe nào dưới đây? ',
      'ansa': 'Xe mô tô hai bánh có dung tích xi-lanh đến 125 cm3 hoặc có công suất động cơ điện đến 11 kW.',
      'ansb': 'Xe mô tô hai bánh có dung tích xi-lanh trên 125 cm3 hoặc có công suất động cơ điện trên 11 kW.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 17 - 127',
      'content': 'Người có Giấy phép lái xe ô tô hạng B được phép điều khiển loại xe nào dưới đây?',
      'ansa': 'Xe ô tô chở người đến 08 chỗ (không kể chỗ của người lái xe).',
      'ansb': 'Xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế đến 3.500 kg.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 18 - 128',
      'content': 'Người có Giấy phép lái xe hạng C1 được điều khiển loại xe nào dưới đây?',
      'ansa': 'Xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế trên 7.500 kg; các loại xe ô tô tải quy định cho giấy phép lái xe hạng C1 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansb': 'Xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế trên 3.500 kg đến 7.500 kg; các loại xe ô tô tải quy định cho giấy phép lái xe hạng C1 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 19 - 129',
      'content': 'Người có Giấy phép lái xe hạng C được điều khiển loại xe nào dưới đây?',
      'ansa': 'Xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế trên 3.500 kg đến 7.500 kg; các loại xe ô tô tải quy định cho giấy phép lái xe hạng C1 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansb': 'Xe ô tô tải và ô tô chuyên dùng có khối lượng toàn bộ theo thiết kế trên 7.500 kg; các loại xe ô tô tải quy định cho giấy phép lái xe hạng C kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 20 - 130',
      'content': 'Người có Giấy phép lái xe hạng D1 được điều khiển loại xe nào dưới đây?',
      'ansa': 'Xe ô tô chở người (kể cả xe buýt) trên 16 chỗ (không kể chỗ của người lái xe) đến 29 chỗ (không kể chỗ của người lái xe); các loại xe ô tô chở người quy định cho giấy phép lái xe hạng D1 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansb': 'Xe ô tô chở người trên 08 chỗ (không kể chỗ của người lái xe) đến 16 chỗ (không kể chỗ của người lái xe); các loại xe ô tô chở người quy định cho giấy phép lái xe hạng D1 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 21 - 131',
      'content': 'Người có Giấy phép lái xe hạng D2 được điều khiển loại xe nào dưới đây?',
      'ansa': 'Xe ô tô chở người (kể cả xe buýt) trên 16 chỗ (không kể chỗ của người lái xe) đến 29 chỗ (không kể chỗ của người lái xe); các loại xe ô tô chở người quy định cho giấy phép lái xe hạng D2 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansb': 'Xe ô tô chở người trên 08 chỗ (không kể chỗ của người lái xe) đến 16 chỗ (không kể chỗ của người lái xe); các loại xe ô tô chở người quy định cho giấy phép lái xe hạng D1 kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 1,
      'title': 'Câu hỏi 22 - 132',
      'content': 'Người có Giấy phép lái xe hạng D được điều khiển loại xe nào dưới đây?',
      'ansa': 'Xe ô tô chở người (kể cả xe buýt) trên 29 chỗ (không kể chỗ của người lái xe); xe ô tô chở người giường nằm; các loại xe ô tô chở người quy định cho giấy phép lái xe hạng D kéo rơ moóc có khối lượng toàn bộ theo thiết kế đến 750 kg.',
      'ansb': 'Xe ô tô chở người (kể cả xe buýt) trên 16 chỗ (không kể chỗ của người lái xe) đến 29 chỗ (không kể chỗ của người lái xe).',
      'ansc': 'Các loại xe ô tô quy định cho giấy phép lái xe hạng C kéo rơ moóc có khối lượng toàn bộ theo thiết kế trên 750 kg; xe ô tô đầu kéo kéo sơ mi rơ moóc.',
      'ansd': 'Ý 1 và ý 2.',
      'ansright': 'D',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });




    await db.insert('questions', {
      'topic_id': 2,
      'title': 'Câu hỏi 16 - 196',
      'content': 'Khi sơ cứu ban đầu cho người bị tai nạn giao thông đường bộ không còn hô hấp, người lái xe và người có mặt tại hiện trường vụ tai nạn phải thực hiện các công việc gì dưới đây?',
      'ansa': 'Đặt nạn nhân nằm ngửa, khai thông đường thở của nạn nhân; thực hiện các biện pháp hô hấp nhân tạo.',
      'ansb': 'Thực hiện các biện pháp hô hấp nhân tạo.',
      'ansc': '',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 2,
      'title': 'Câu hỏi 17 - 197',
      'content': 'Hành vi bỏ trốn sau khi gây tai nạn để trốn tránh trách nhiệm hoặc khi có điều kiện mà cố ý không cứu giúp người bị tai nạn giao thông có bị nghiêm cấm hay không?',
      'ansa': 'Không bị nghiêm cấm.',
      'ansb': 'Nghiêm cấm tuỳ từng trường hợp cụ thể. ',
      'ansc': 'Bị nghiêm cấm.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 1,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 2,
      'title': 'Câu hỏi 18 - 198',
      'content': 'Khi đang lái xe, thấy một người đi bộ đang sang đường trên vạch kẻ đường dành cho người đi bộ, người lái xe nên làm gì?',
      'ansa': 'Giảm tốc độ và nhường đường cho người đi bộ.',
      'ansb': 'Bấm còi để họ đi nhanh hơn.',
      'ansc': 'Tiếp tục đi nếu đang vội.',
      'ansd': 'Vượt qua nếu thấy khoảng trống đủ rộng.',
      'ansright': 'A',
      'mandatory': 1,
      'pos': 1,
      'status': 'active',
    });


    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 38 - 243',
      'content': 'Khi lái xe ô tô trên mặt đường có nhiều "ổ gà", người lái xe phải thực hiện thao tác như thế nào để bảo đảm an toàn?',
      'ansa': 'Giảm tốc độ, về số thấp và giữ đều ga.',
      'ansb': 'Tăng tốc độ cho xe lướt qua nhanh.',
      'ansc': 'Tăng tốc độ, đánh lái liên tục để tránh "ổ gà".',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 39 - 244',
      'content': 'Khi điều khiển xe ô tô gặp mưa to hoặc sương mù, người lái xe phải làm gì để bảo đảm an toàn?',
      'ansa': 'Bật đèn chiếu gần và đèn vàng (nếu có), điều khiển gạt nước, điều khiển ô tô đi với tốc độ chậm để có thể quan sát được; tìm chỗ an toàn dừng xe, bật đèn dừng khẩn cấp báo hiệu cho các xe khác biết.',
      'ansb': 'Bật đèn chiếu xa và đèn vàng, điều khiển gạt nước, tăng tốc độ điều khiển ô tô qua khỏi khu vực mưa hoặc sương mù.',
      'ansc': 'Tăng tốc độ, bật đèn pha vượt qua xe chạy phía trước.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 40 - 245 ',
      'content': 'Điều khiển xe ô tô trong trời mưa, người lái xe phải xử lý như thếnào để bảo đảm an toàn?',
      'ansa': 'Giảm tốc độ, tăng cường quan sát, không nên phanh gấp, không nên tăng ga hay đánh vô lăng đột ngột, bật đèn chiếu gần, mở chế độ gạt nước ở chế độ phù hợp để đảm bảo quan sát.',
      'ansb': 'Phanh gấp khi xe đi vào vũng nước và tăng ga ngay sau khi ra khỏi vũng nước.',
      'ansc': 'Bật đèn chiếu xa, tăng tốc độ điều khiển ô tô qua khỏi khu vực mưa',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 1,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 41 - 246',
      'content': 'Khi lùi xe, người lái xe phải xử lý như thế nào để bảo đảm an toàn giao thông?',
      'ansa': 'Quan sát bên trái, bên phải, phía sau xe, có tín hiệu cần thiết và lùi xe với tốc độ phù hợp.',
      'ansb': 'Quan sát phía trước xe và lùi xe với tốc độ nhanh.',
      'ansc': 'Quan sát bên trái và phía trước của xe và lùi xe với tốc độ nhanh.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 1,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 42 - 247',
      'content': 'Điều khiển xe ô tô trong khu vực đông dân cư cần lưu ý điều gì dưới đây?',
      'ansa': 'Giảm tốc độ đến mức an toàn, quan sát, nhường đường cho người đi bộ, giữkhoảng cách an toàn với các xe phía trước.',
      'ansb': 'Đi đúng làn đường quy định, chỉ được chuyển làn đường ở nơi cho phép, nhưng phải quan sát.',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 43 - 248',
      'content': 'Khi điều khiển xe ô tô nhập vào đường cao tốc người lái xe cần thực hiện như thế nào dưới đây để bảo đảm an toàn giao thông?',
      'ansa': 'Quan sát, phát tín hiệu, nhường đường cho các xe đang chạy trên đường cao tốc, khi đủ điều kiện an toàn thì tăng tốc độ cho xe nhập vào làn đường cao tốc, nếu có làn đường tăng tốc thì phải cho xe chạy trên làn đường đó trước khi cho xe nhập vào làn của đường cao tốc.',
      'ansb': 'Phát tín hiệu, quan sát các xe đang chạy phía trước, nếu bảo đảm các điều kiện an toàn thì tăng tốc độ cho xe nhập ngay vào làn đường cao tốc.',
      'ansc': 'Phát tín hiệu và lái xe nhập vào làn đường tăng tốc, quan sát các xe phía sau đang chạy trên đường cao tốc, khi đủ điều kiện an toàn thì giảm tốc độ, từ từ cho xe nhập vào làn đường cao tốc.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 44 - 249',
      'content': 'Khi điều khiển xe ô tô ra khỏi đường cao tốc người lái xe cần thực hiện như thế nào dưới đây để bảo đảm an toàn giao thông?',
      'ansa': 'Quan sát phía trước để tìm biển báo chỉ dẫn "lối ra đường cao tốc", kiểm tra tình trạng giao thông phía sau và bên phải, nếu bảo đảm điều kiện an toàn thì phát tín hiệu và điều khiển xe chuyển dần sang làn bên phải, nếu có làn đường giảm tốc thì phải cho xe di chuyển trên làn đường đó trước khi ra khỏi đường cao tốc.',
      'ansb': 'Quan sát phía trước để tìm biển báo chỉ dẫn "lối ra đường cao tốc", trường hợp vượt qua "lối ra đường cao tốc" thì phát tín hiệu, di chuyển sang làn đường giảm tốc và lùi xe quay trở lại',
      'ansc': '',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 3,
      'title': 'Câu hỏi 45 - 250',
      'content': 'Người lái xe được dừng xe, đỗ xe trên làn dừng khẩn cấp của đường cao tốc trong trường hợp nào dưới đây?',
      'ansa': 'Xe gặp sự cố, tai nạn hoặc trường hợp khẩn cấp không thể di chuyển bình thường.',
      'ansb': 'Để nghỉ ngơi, đi vệ sinh, chụp ảnh, làm việc riêng...',
      'ansc': 'Cả hai ý trên.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });



    await db.insert('questions', {
      'topic_id': 4,
      'title': 'Câu hỏi 27 - 290',
      'content': 'Khi khởi động xe ô tô số tự động có trang bị chìa khóa thông minh có cần đạp hết hành trình bàn đạp chân phanh hay không?',
      'image': 'assets/images/cau290.png',
      'ansa': 'Phải đạp hết hành trình bàn đạp chân phanh.',
      'ansb': 'Không cần đạp phanh.',
      'ansc': 'Tùy từng trường hợp.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 4,
      'title': 'Câu hỏi 28 - 291',
      'content': 'Ắc quy được trang bị trên xe ô tô có tác dụng gì dưới đây?',
      'ansa': 'Giúp người lái xe kịp thời tạo xung lực tối đa lên hệ thống phanh trong khoảnh khắc đầu tiên của tình huống khẩn cấp.',
      'ansb': 'Ổn định chuyển động của xe ô tô khi đi vào đường vòng.',
      'ansc': 'Hỗ trợ người lái xe khởi hành ngang dốc.',
      'ansd': 'Để tích trữ điện năng, cung cấp cho các phụ tải khi máy phát chưa làm việc.',
      'ansright': 'D',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 4,
      'title': 'Câu hỏi 29 - 292 ',
      'content': 'Máy phát điện được trang bị trên xe ô tô có tác dụng gì dưới đây?',
      'ansa': 'Để phát điện năng cung cấp cho các phụ tải làm việc và nạp điện cho ắc quy.',
      'ansb': 'Ổn định chuyển động của xe ô tô khi đi vào đường vòng.',
      'ansc': 'Hỗ trợ người lái xe khởi hành ngang dốc.',
      'ansd': 'Để tích trữ điện năng và cung cấp điện cho các phụ tải làm việc.',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 4,
      'title': 'Câu hỏi 30 - 293',
      'content': 'Dây đai an toàn được trang bị trên xe ô tô có tác dụng gì dưới đây?',
      'ansa': 'Ổn định chuyển động của xe ô tô khi đi vào đường vòng.',
      'ansb': 'Giữ chặt người lái và hành khách trên ghế ngồi khi xe ô tô đột ngột dừng lại.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 4,
      'title': 'Câu hỏi 31 - 294',
      'content': 'Túi khí được trang bị trên xe ô tô có tác dụng gì dưới đây?',
      'ansa': 'Giữ chặt người lái và hành khách trên ghế ngồi khi xe ô tô đột ngột dừng lại.',
      'ansb': 'Giảm khả năng va đập của một số bộ phận cơ thể quan trọng với các vật thể trong xe.',
      'ansc': 'Hấp thụ một phần lực va đập lên người lái và hành khách.',
      'ansd': 'Ý 2 và ý 3.',
      'ansright': 'D',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });




    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 1 - 486',
      'content': 'Theo hướng mũi tên, xe nào chấp hành đúng quy tắc giao thông?',
      'image': 'assets/images/cau486.png',
      'ansa': 'Xe khách, xe tải, xe mô tô.',
      'ansb': 'Xe tải, xe mô tô.',
      'ansc': 'Chỉ xe con.',
      'ansd': '',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 2 - 487',
      'content': 'Theo hướng mũi tên, thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau487.png',
      'ansa': 'Xe tải, xe khách, xe con, xe mô tô.',
      'ansb': 'Xe tải, xe mô tô, xe khách, xe con.',
      'ansc': 'Xe khách, xe tải, xe con, xe mô tô.',
      'ansd': 'Xe mô tô, xe khách, xe tải, xe con.',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 3 - 488',
      'content': 'Theo hướng mũi tên, thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau488.png',
      'ansa': 'Xe công an đi làm nhiệm vụ khẩn cấp, xe con, xe tải, xe khách.',
      'ansb': 'Xe công an đi làm nhiệm vụ khẩn cấp, xe khách, xe con, xe tải.',
      'ansc': 'Xe công an đi làm nhiệm vụ khẩn cấp, xe tải, xe khách, xe con.',
      'ansd': 'Xe con, xe công an đi làm nhiệm vụ khẩn cấp, xe tải, xe khách.',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 4 - 489',
      'content': 'Theo hướng mũi tên, thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau489.png',
      'ansa': 'Xe tải, xe công an đi làm nhiệm vụ khẩn cấp, xe khách, xe con.',
      'ansb': 'Xe công an đi làm nhiệm vụ khẩn cấp, xe khách, xe con, xe tải.',
      'ansc': 'Xe công an đi làm nhiệm vụ khẩn cấp, xe con, xe tải, xe khách.',
      'ansd': 'Xe công an đi làm nhiệm vụ khẩn cấp, xe tải, xe khách, xe con.',
      'ansright': 'D',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 5 - 490',
      'content': 'Theo hướng mũi tên, thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau490.png',
      'ansa': 'Xe tải, xe con, xe mô tô.',
      'ansb': 'Xe con, xe tải, xe mô tô.',
      'ansc': 'Xe mô tô, xe con, xe tải.',
      'ansd': 'Xe con, xe mô tô, xe tải.',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 6 - 491',
      'content': 'Xe nào phải nhường đường trong trường hợp này?',
      'image': 'assets/images/cau491.png',
      'ansa': 'Xe con.',
      'ansb': 'Xe tải.',
      'ansc': '',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 7 - 492',
      'content': 'Trường hợp này xe nào được quyền đi trước?',
      'image': 'assets/images/cau492.png',
      'ansa': 'Xe mô tô.',
      'ansb': 'Xe con.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 8 - 493',
      'content': 'Thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau493.png',
      'ansa': 'Xe con (A), xe cứu thương đi làm nhiệm vụ cấp cứu, xe con (B).',
      'ansb': '2.Xe cứu thương đi làm nhiệm vụ cấp cứu, xe con (B), xe con (A).',
      'ansc': '3.Xe con (B), xe con (A), xe cứu thương đi làm nhiệm vụ cấp cứu.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 9 - 494',
      'content': 'Thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau494.png',
      'ansa': '1.Xe cứu thương đi làm nhiệm vụ cấp cứu, xe chữa cháy đi làm nhiệm vụ chữa cháy, xe con.',
      'ansb': 'Xe chữa cháy đi làm nhiệm vụ chữa cháy, xe cứu thương đi làm nhiệm vụ cấp cứu, xe con.',
      'ansc': 'Xe chữa cháy đi làm nhiệm vụ chữa cháy, xe cứu thương đi làm nhiệm vụ cấp cứu, xe con.',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 10 - 495',
      'content': 'Xe nào được quyền đi trước trong trường hợp này?',
      'image': 'assets/images/cau495.png',
      'ansa': 'Xe mô tô.',
      'ansb': 'Xe cứu thương đi làm nhiệm vụ cấp cứu.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 11 - 496',
      'content': 'Theo hướng mũi tên, xe nào phải nhường đường đi cuối cùng qua nơi giao nhau này?',
      'image': 'assets/images/cau496.png',
      'ansa': 'Xe khách.',
      'ansb': 'Xe tải.',
      'ansc': 'Xe con.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 12 - 497',
      'content': 'Theo hướng mũi tên, xe nào phải nhường đường là đúng quy tắc giao thông?',
      'image': 'assets/images/cau497.png',
      'ansa': 'Xe con.',
      'ansb': 'Xe tải.',
      'ansc': '',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 13 - 498',
      'content': 'Xe nào được quyền đi trước trong trường hợp này?',
      'image': 'assets/images/cau498.png',
      'ansa': 'Xe công an đi làm nhiệm vụ khẩn cấp.',
      'ansb': 'Xe chữa cháy đi làm nhiệm vụ chữa cháy.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 14 - 499',
      'content': 'Theo tín hiệu đèn, xe nào được phép đi?',
      'image': 'assets/images/cau499.png',
      'ansa': 'Xe con và xe khách.',
      'ansb': 'Xe mô tô.',
      'ansc': '',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 15 - 500',
      'content': 'Theo tín hiệu đèn, xe nào đi là đúng quy tắc giao thông?',
      'image': 'assets/images/cau500.png',
      'ansa': 'Xe khách, xe mô tô.',
      'ansb': 'Xe con, xe tải.',
      'ansc': 'Xe tải, xe mô tô.',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 16 - 501',
      'content': 'Trong trường hợp này xe nào được quyền đi trước?',
      'image': 'assets/images/cau501.png',
      'ansa': 'Xe công an đi làm nhiệm vụ khẩn cấp.',
      'ansb': 'Xe quân sự đi làm nhiệm vụ khẩn cấp.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 17 - 502',
      'content': 'Theo tín hiệu đèn, xe tải đi theo hướng nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau502.png',
      'ansa': 'Hướng 2, 3, 4.',
      'ansb': 'Chỉ hướng 1.',
      'ansc': 'Hướng 1 và 2.',
      'ansd': 'Hướng 3 và 4.',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 18 - 503',
      'content': 'Các xe đi theo hướng mũi tên, những xe nào vi phạm quy tắc giao thông?',
      'image': 'assets/images/cau503.png',
      'ansa': 'Xe khách, xe tải, xe mô tô.',
      'ansb': 'Xe tải, xe con, xe mô tô.',
      'ansc': 'Xe khách, xe con, xe mô tô.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 19 - 504',
      'content': 'Theo hướng mũi tên, thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau504.png',
      'ansa': 'Xe khách, xe tải, xe mô tô, xe con.',
      'ansb': 'Xe con, xe khách, xe tải, xe mô tô.',
      'ansc': 'Xe mô tô, xe tải, xe khách, xe con.',
      'ansd': 'Xe mô tô, xe tải, xe con, xe khách.',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 20 - 505',
      'content': 'Trong trường hợp này xe nào đỗ vi phạm quy tắc giao thông?',
      'image': 'assets/images/cau505.png',
      'ansa': 'Xe tải.',
      'ansb': 'Xe con và mô tô.',
      'ansc': 'Cả ba xe.',
      'ansd': 'Xe con và xe tải.',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 21 - 506',
      'content': 'Theo hướng mũi tên, xe nào được quyền đi trước?',
      'image': 'assets/images/cau506.png',
      'ansa': 'Xe tải.',
      'ansb': 'Xe con (B).',
      'ansc': 'Xe con (A).',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 22 - 507',
      'content': 'Theo hướng mũi tên, những hướng nào xe gắn máy được phép đi?',
      'image': 'assets/images/cau507.png',
      'ansa': 'Cả ba hướng.',
      'ansb': 'Chỉ hướng 1 và 3.',
      'ansc': 'Chỉ hướng 1.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 23 - 508',
      'content': 'Xe nào đỗ vi phạm quy tắc giao thông?',
      'image': 'assets/images/cau508.png',
      'ansa': 'Cả hai xe.',
      'ansb': 'Không xe nào vi phạm.',
      'ansc': 'Chỉ xe mô tô vi phạm.',
      'ansd': 'Chỉ xe tải vi phạm.',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 24 - 509',
      'content': 'Xe nào đỗ vi phạm quy tắc giao thông?',
      'image': 'assets/images/cau509.png',
      'ansa': 'Chỉ xe mô tô.',
      'ansb': 'Chỉ xe tải.',
      'ansc': 'Cả ba xe.',
      'ansd': 'Chỉ xe mô tô và xe tải.',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 25 - 510',
      'content': 'Xe tải kéo xe mô tô ba bánh như hình này có đúng quy tắc giao thông không?',
      'image': 'assets/images/cau510.png',
      'ansa': 'Đúng.',
      'ansb': 'Không đúng.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 26 - 511',
      'content': 'Theo hướng mũi tên, hướng nào xe không được phép đi?',
      'image': 'assets/images/cau511.png',
      'ansa': 'Hướng 2 và 5.',
      'ansb': 'Chỉ hướng 1.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 27 - 512',
      'content': 'Theo hướng mũi tên, những hướng nào xe ô tô không được phép đi?',
      'image': 'assets/images/cau512.png',
      'ansa': 'Hướng 1 và 2.',
      'ansb': 'Hướng 3.',
      'ansc': 'Hướng 1 và 4.',
      'ansd': 'Hướng 2 và 3.',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 28 - 513',
      'content': 'Xe nào vượt đúng quy tắc giao thông?',
      'image': 'assets/images/cau513.png',
      'ansa': 'Cả hai xe đều đúng.',
      'ansb': 'Xe con.',
      'ansc': 'Xe khách.',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 29 - 514',
      'content': '',
      'image': 'assets/images/cau514.png',
      'ansa': 'Theo hướng mũi tên, gặp biển hướng đi phải theo đặt trước ngã tư, những hướng nào xe được phép đi?',
      'ansb': 'Hướng 2 và 3.',
      'ansc': 'Hướng 1, 2 và 3.',
      'ansd': 'Hướng 1 và 3.',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 30 - 515',
      'content': 'Xe kéo nhau như hình này có vi phạm quy tắc giao thông không?',
      'image': 'assets/images/cau515.png',
      'ansa': 'Không.',
      'ansb': 'Vi phạm',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 31 - 516',
      'content': 'Xe nào phải nhường đường trong trường hợp này?',
      'image': 'assets/images/cau516.png',
      'ansa': 'Xe khách.',
      'ansb': 'Xe tải.',
      'ansc': '',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 32 - 517',
      'content': 'Xe nào được quyền đi trước trong trường hợp này?',
      'image': 'assets/images/cau517.png',
      'ansa': 'Xe con.',
      'ansb': 'Xe mô tô.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 33 - 518',
      'content': 'Xe kéo nhau trong trường hợp này đúng quy định không?',
      'image': 'assets/images/cau518.png',
      'ansa': 'Không đúng.',
      'ansb': 'Đúng.',
      'ansc': '',
      'ansd': '',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 34 - 519',
      'content': 'Theo hướng mũi tên, những hướng nào xe ô tô con được phép đi?',
      'image': 'assets/images/cau519.png',
      'ansa': 'Hướng 1.',
      'ansb': 'Hướng 1, 3 và 4.',
      'ansc': 'Hướng 2, 3 và 4.',
      'ansd': 'Cả bốn hướng.',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 35 - 520',
      'content': 'Theo hướng mũi tên, thứ tự các xe đi như thế nào là đúng quy tắc giao thông?',
      'image': 'assets/images/cau520.png',
      'ansa': 'Xe con (A), xe mô tô, xe con (B), xe đạp.',
      'ansb': 'Xe con (B), xe đạp, xe mô tô, xe con (A).',
      'ansc': 'Xe con (A), xe con (B), xe mô tô + xe đạp.',
      'ansd': 'Xe mô tô + xe đạp, xe con (A), xe con (B).',
      'ansright': 'D',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 36 - 521',
      'content': 'Theo hướng mũi tên, những hướng nào xe tải được phép đi?',
      'image': 'assets/images/cau521.png',
      'ansa': 'Chỉ hướng 1.',
      'ansb': 'Hướng 1, 3 và 4.',
      'ansc': 'Hướng 1, 2 và 3.',
      'ansd': 'Cả bốn hướng.',
      'ansright': 'A',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 37 - 522',
      'content': 'Những hướng nào xe tải được phép đi?',
      'image': 'assets/images/cau522.png',
      'ansa': 'Cả ba hướng.',
      'ansb': 'Hướng 2 và 3.',
      'ansc': '',
      'ansd': '',
      'ansright': 'B',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });

    await db.insert('questions', {
      'topic_id': 6,
      'title': 'Câu hỏi 38 - 523',
      'content': 'Những hướng nào xe ô tô tải được phép đi?',
      'image': 'assets/images/cau523.png',
      'ansa': 'Chỉ hướng 1.',
      'ansb': 'Hướng 1 và 4.',
      'ansc': 'Hướng 1 và 5.',
      'ansd': 'Hướng 1, 4 và 5.',
      'ansright': 'C',
      'mandatory': 0,
      'pos': 1,
      'status': 'active',
    });



  }
  // Phương thức onUpgrade để thêm cột answers
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE results ADD COLUMN answers TEXT');
    }
  }



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
