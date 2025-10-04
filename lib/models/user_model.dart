class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password; // 🚨 thực tế nên hash
  final String? avatar;  
  final String? phone;   // ✅ thêm
  final String? address; // ✅ thêm

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.avatar,
    this.phone,
    this.address,
  });

  // Tạo UserModel từ Map (SQLite query)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      avatar: map['avatar'] as String?,
      phone: map['phone_number'] as String?, // ✅ map DB -> field Dart
      address: map['address'] as String?,
    );
  }

  // Chuyển UserModel thành Map (lưu vào SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'avatar': avatar,
      'phone_number': phone, // ✅ giữ key gốc DB
      'address': address,
    };
  }

  // JSON cho SharedPreferences
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}
