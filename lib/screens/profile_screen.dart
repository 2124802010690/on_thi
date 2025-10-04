import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../services/db_helper.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'update_info_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUser();
  }

Future<void> _loadUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');

  if (userId != null) {
    final dbUser = await DBHelper().getUserById(userId);
    if (dbUser != null) {
      if (!mounted) return;
      setState(() {
        _user = dbUser;
      });
      return;
    }
  }

  // fallback: nếu không có userId trong prefs (hoặc DB không trả về), dùng widget.user
  if (!mounted) return;
  setState(() {
    _user = widget.user;
  });
}

Future<void> _saveUser(UserModel updatedUser) async {
  // Lưu trực tiếp vào SQLite DB
  await DBHelper().updateUser(updatedUser);
}

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = basename(pickedFile.path);
    final savedImage =
        await File(pickedFile.path).copy('${appDir.path}/$fileName');

    // Tạo user mới dựa trên _user hiện có — giữ nguyên phone, address,...
    final updated = UserModel(
      id: _user.id,
      name: _user.name,
      email: _user.email,
      password: _user.password,
      phone: _user.phone,
      address: _user.address,
      avatar: savedImage.path,
    );

    // Update state và DB
    if (!mounted) return;
    setState(() {
      _user = updated;
    });

    await DBHelper().updateUser(updated);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      appBar: AppBar(
        title: const Text("Thông tin cá nhân", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: (_user.avatar != null && File(_user.avatar!).existsSync())
                          ? FileImage(File(_user.avatar!))
                          : const AssetImage("assets/images/avatar.png") as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user.name.isNotEmpty ? _user.name : "Học viên",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user.email,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  _buildInfoRow(Icons.badge, "Mã học viên", _user.id?.toString() ?? "Chưa có"),
                  // ✅ Số điện thoại
                  _buildInfoRow(Icons.phone, "Số điện thoại", _user.phone ?? "Chưa có"),

                  // ✅ Địa chỉ
                  _buildInfoRow(Icons.home, "Địa chỉ", _user.address ?? "Chưa có"),
                                    const SizedBox(height: 30),
                  _buildActionButtons(context),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );

                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Đăng xuất", style: TextStyle(fontSize: 16, color: Colors.white)),
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
  await prefs.remove('userId');
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
            final updatedUser = await Navigator.push<UserModel?>(
              context,
              MaterialPageRoute(
                builder: (context) => UpdateInfoScreen(user: _user),
              ),
            );
            if (updatedUser != null) {
              setState(() {
                _user = updatedUser;
              });
              _saveUser(_user);
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
                builder: (context) => ChangePasswordScreen(userId: _user.id!),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
