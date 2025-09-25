import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_helper.dart';
import 'home_page.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Đã sửa từ usernameController thành emailController
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController();
  String _error = '';

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final user = await DBHelper().loginUser(
        // Gọi hàm loginUser với email và password
        _emailController.text.trim(), 
        _passwordController.text,
      );

      if (!mounted) return;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('user');
        
        // Tạo một biến để chứa dữ liệu cuối cùng
        Map<String, dynamic> finalUser = user;

        if (userData != null) {
          final savedUser = Map<String, dynamic>.from(jsonDecode(userData));
          
          // Hợp nhất dữ liệu: dữ liệu từ DB (user) sẽ được ưu tiên,
          // sau đó các trường đã được cập nhật từ SharedPreferences (savedUser)
          // sẽ ghi đè lên để giữ lại thông tin mới nhất.
          finalUser = {
            ...user, // Dữ liệu từ cơ sở dữ liệu
            ...savedUser, // Dữ liệu đã cập nhật từ SharedPreferences
          };
        }
        
        // Lưu lại finalUser đã hợp nhất vào SharedPreferences
        await prefs.setString('user', jsonEncode(finalUser));
        
        // Chuyển đến màn hình chính với dữ liệu đã được cập nhật
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(user: finalUser)),
        );
      } else {
        setState(() {
          _error = 'Tên đăng nhập hoặc mật khẩu không đúng';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 10),
                const Text(
                  'GPLX Hạng B',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Sửa từ _usernameController thành _emailController
                          _buildTextField(_emailController, 'Email', Icons.email),
                          const SizedBox(height: 20),
                          _buildTextField(_passwordController, 'Mật khẩu', Icons.lock, obscureText: true),
                          const SizedBox(height: 20),
                          if (_error.isNotEmpty)
                            Text(
                              _error,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Bạn chưa có tài khoản? Đăng ký ngay.',
                              style: TextStyle(color: Color(0xFF003366)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng nhập $hintText';
          }
          return null;
        },
      ),
    );
  }
}