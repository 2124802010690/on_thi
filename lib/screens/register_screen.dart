import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db_helper.dart';
import '../models/user_model.dart';

enum AlphaOption { both, lowercase, uppercase }
enum NonAlphaOption { both, numbers, symbols }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _message = '';
  bool _isSuccess = false;

  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = "Very Weak";

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password generator options
  int _genLength = 12;
  AlphaOption _alphaOption = AlphaOption.both;
  NonAlphaOption _nonAlphaOption = NonAlphaOption.both;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(
        () => _checkPasswordStrength(_passwordController.text));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Tạo mật khẩu ngẫu nhiên
  String _generatePassword({
    int length = 12,
    AlphaOption alpha = AlphaOption.both,
    NonAlphaOption nonAlpha = NonAlphaOption.both,
  }) {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_-+=<>?';

    String pool = '';
    if (alpha == AlphaOption.both) {
      pool += lower + upper;
    } else if (alpha == AlphaOption.lowercase) {
      pool += lower;
    } else {
      pool += upper;
    }

    if (nonAlpha == NonAlphaOption.both) {
      pool += numbers + symbols;
    } else if (nonAlpha == NonAlphaOption.numbers) {
      pool += numbers;
    } else {
      pool += symbols;
    }

    if (pool.isEmpty) pool = lower + numbers;

    final rand = Random.secure();
    return List.generate(length, (index) => pool[rand.nextInt(pool.length)])
        .join();
  }

  /// Đánh giá độ mạnh mật khẩu
  void _checkPasswordStrength(String password) {
    double strength = 0;

    if (password.isEmpty) {
      strength = 0;
      _passwordStrengthLabel = "Very Weak";
    } else {
      if (password.length >= 8) strength += 0.25;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
      if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
        strength += 0.25;
      }

      if (strength <= 0.25) {
        _passwordStrengthLabel = "Very Weak";
      } else if (strength <= 0.5) {
        _passwordStrengthLabel = "Weak";
      } else if (strength <= 0.75) {
        _passwordStrengthLabel = "Medium";
      } else {
        _passwordStrengthLabel = "Strong";
      }
    }

    setState(() {
      _passwordStrength = strength;
    });
  }

  /// Bottom sheet chỉnh option generator
  void _openGeneratorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        int tmpLength = _genLength;
        AlphaOption tmpAlpha = _alphaOption;
        NonAlphaOption tmpNonAlpha = _nonAlphaOption;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Wrap(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Password Generator',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Length: $tmpLength (10-18)'),
                  Slider(
                    min: 10,
                    max: 18,
                    divisions: 8,
                    value: tmpLength.toDouble(),
                    onChanged: (v) =>
                        setModalState(() => tmpLength = v.round()),
                  ),
                  const SizedBox(height: 8),
                  const Text('Alpha Characters:'),
                  Column(
                    children: [
                      RadioListTile<AlphaOption>(
                        title: const Text('Both (abcABC)'),
                        value: AlphaOption.both,
                        groupValue: tmpAlpha,
                        onChanged: (v) => setModalState(() => tmpAlpha = v!),
                      ),
                      RadioListTile<AlphaOption>(
                        title: const Text('Lowercase (abc)'),
                        value: AlphaOption.lowercase,
                        groupValue: tmpAlpha,
                        onChanged: (v) => setModalState(() => tmpAlpha = v!),
                      ),
                      RadioListTile<AlphaOption>(
                        title: const Text('Uppercase (ABC)'),
                        value: AlphaOption.uppercase,
                        groupValue: tmpAlpha,
                        onChanged: (v) => setModalState(() => tmpAlpha = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Non Alpha Characters:'),
                  Column(
                    children: [
                      RadioListTile<NonAlphaOption>(
                        title: const Text('Both (1@3\$)'),
                        value: NonAlphaOption.both,
                        groupValue: tmpNonAlpha,
                        onChanged: (v) => setModalState(() => tmpNonAlpha = v!),
                      ),
                      RadioListTile<NonAlphaOption>(
                        title: const Text('Numbers (123)'),
                        value: NonAlphaOption.numbers,
                        groupValue: tmpNonAlpha,
                        onChanged: (v) => setModalState(() => tmpNonAlpha = v!),
                      ),
                      RadioListTile<NonAlphaOption>(
                        title: const Text('Symbols (@#\$)'),
                        value: NonAlphaOption.symbols,
                        groupValue: tmpNonAlpha,
                        onChanged: (v) => setModalState(() => tmpNonAlpha = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _genLength = tmpLength;
                        _alphaOption = tmpAlpha;
                        _nonAlphaOption = tmpNonAlpha;
                      });
                      String newPass = _generatePassword(
                        length: _genLength,
                        alpha: _alphaOption,
                        nonAlpha: _nonAlphaOption,
                      );
                      _passwordController.text = newPass;
                      _confirmPasswordController.text = newPass;
                      _checkPasswordStrength(newPass);
                      Clipboard.setData(ClipboardData(text: newPass));
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366)),
                    child: const Text('Generate & Use'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Đăng ký
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password != confirm) {
      setState(() {
        _message = 'Mật khẩu xác nhận không khớp';
        _isSuccess = false;
      });
      return;
    }

    final user = UserModel(
      name: username,
      email: email,
      password: password,
    );

    final result = await DBHelper().registerUser(user);

    if (!mounted) return;

    if (result == -1) {
      setState(() {
        _message = 'Email đã tồn tại! Vui lòng dùng email khác.';
        _isSuccess = false;
      });
    } else {
      setState(() {
        _message = 'Đăng ký thành công!';
        _isSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công, quay lại đăng nhập")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      IconData icon,
      {bool obscureText = false, Widget? suffixIcon}) {
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          suffixIcon: suffixIcon,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng nhập $hintText';
          }
          if (hintText == 'Xác nhận mật khẩu' &&
              value != _passwordController.text) {
            return 'Mật khẩu không khớp';
          }
          return null;
        },
      ),
    );
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
              children: const [
                Icon(Icons.directions_car, color: Colors.white, size: 80),
                SizedBox(height: 10),
                Text(
                  'GPLX Hạng B',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5)
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Đăng ký tài khoản',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            _usernameController,
                            'Tên đăng nhập',
                            Icons.person,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            _emailController,
                            'Email',
                            Icons.email,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            _passwordController,
                            'Mật khẩu',
                            Icons.lock,
                            obscureText: _obscurePassword,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    // Sinh mật khẩu mới ngay lập tức
                                    String newPass = _generatePassword(
                                      length: _genLength,
                                      alpha: _alphaOption,
                                      nonAlpha: _nonAlphaOption,
                                    );
                                    setState(() {
                                      _passwordController.text = newPass;
                                      _confirmPasswordController.text = newPass;
                                      _checkPasswordStrength(newPass);
                                    });
                                    Clipboard.setData(ClipboardData(text: newPass));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Mật khẩu mới đã được tạo & copy")),
                                    );
                                  },
                                ),

                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: _passwordStrength,
                            backgroundColor: Colors.grey[300],
                            color: _passwordStrength >= 0.75
                                ? Colors.green
                                : _passwordStrength >= 0.5
                                    ? Colors.orange
                                    : Colors.red,
                            minHeight: 6,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Strength: $_passwordStrengthLabel",
                            style: TextStyle(
                              color: _passwordStrength >= 0.75
                                  ? Colors.green
                                  : _passwordStrength >= 0.5
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                                                    Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _openGeneratorDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    minimumSize: const Size(double.infinity, 45),
                                  ),
                                  icon: const Icon(Icons.password),
                                  label: const Text("Password Generator"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_passwordController.text.isNotEmpty) {
                                    Clipboard.setData(
                                      ClipboardData(text: _passwordController.text),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Mật khẩu đã được copy"),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(45, 45),
                                ),
                                icon: const Icon(Icons.copy, size: 20),
                                label: const Text("Copy"),
                              ),
                            ],
                          ),
                          _buildTextField(
                            _confirmPasswordController,
                            'Xác nhận mật khẩu',
                            Icons.lock,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Đăng ký',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Đã có tài khoản? "),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Đăng nhập",
                                  style: TextStyle(color: Color(0xFF003366)),
                                ),
                              ),
                            ],
                          ),
                          if (_message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _message,
                                style: TextStyle(
                                    color: _isSuccess
                                        ? Colors.green
                                        : Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
