import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Thêm thư viện image_picker
import 'package:path_provider/path_provider.dart'; // Thêm thư viện path_provider
import 'package:path/path.dart'; // Thêm thư viện path

import 'login_screen.dart';
import 'update_info_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> user;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() {
        user = jsonDecode(userData);
      });
    }
  }

  Future<void> _saveUser(Map<String, dynamic> updatedUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(updatedUser));
  }

  // Hàm mới để chọn ảnh và cập nhật avatar
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Lấy thư mục lưu trữ cục bộ của ứng dụng
      final appDir = await getApplicationDocumentsDirectory();
      // Tạo một tên file duy nhất để tránh trùng lặp
      final fileName = basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      // Cập nhật đường dẫn ảnh mới vào dữ liệu người dùng
      setState(() {
        user['avatar'] = savedImage.path;
      });

      // Lưu dữ liệu người dùng đã cập nhật vào SharedPreferences
      await _saveUser(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        title: const Text(
          "Thông tin cá nhân",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickImage, // Gán hàm _pickImage cho sự kiện chạm
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          (user['avatar'] != null && File(user['avatar']).existsSync())
                              ? FileImage(File(user['avatar']))
                              : const AssetImage("assets/images/avatar.png") as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user['name'] ?? "Học viên",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user['email'] != null)
                    Text(
                      user['email'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 20),
                    const Divider(),
                  _buildInfoRow(Icons.phone, "Số điện thoại", user['phone'] ?? "Chưa có"),
                  _buildInfoRow(Icons.badge, "Mã học viên", user['id']?.toString() ?? "Chưa có"),
                  _buildInfoRow(Icons.location_on, "Địa chỉ", user['address']?.toString() ?? "Chưa có"),
                  const SizedBox(height: 30),
                  _buildActionButtons(context),
                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Đăng xuất",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.edit,
          label: "Cập nhật",
          onPressed: () async {
            final updatedUser = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpdateInfoScreen(user: user),
              ),
            );
            if (updatedUser != null) {
              setState(() {
                user = {
                  ...user,
                  ...updatedUser,
                };
              });
              _saveUser(user);
            }
          },
        ),
        _buildActionButton(
          icon: Icons.lock,
          label: "Đổi mật khẩu",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangePasswordScreen(
                  userId: user['id'],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}