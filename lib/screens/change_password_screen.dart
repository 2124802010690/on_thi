import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db_helper.dart';

enum AlphaOption { both, lowercase, uppercase }
enum NonAlphaOption { both, numbers, symbols }

class ChangePasswordScreen extends StatefulWidget {
  final int userId;
  const ChangePasswordScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = "Very Weak";

  // Generator options
  int _genLength = 12;
  AlphaOption _alphaOption = AlphaOption.both;
  NonAlphaOption _nonAlphaOption = NonAlphaOption.both;

  String _message = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      _checkPasswordStrength(_newPasswordController.text);
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
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
    return List.generate(length, (index) => pool[rand.nextInt(pool.length)]).join();
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
      if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.25;

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

  /// Đổi mật khẩu
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (newPass != confirm) {
      setState(() {
        _message = 'Mật khẩu xác nhận không khớp';
        _isSuccess = false;
      });
      return;
    }

    final db = DBHelper();
    final user = await db.getUserById(widget.userId);

    if (user == null) {
      setState(() {
        _message = 'Không tìm thấy người dùng';
        _isSuccess = false;
      });
      return;
    }

    final currentPassInDb = user['password'];

    if (currentPassInDb != oldPass) {
      setState(() {
        _message = 'Mật khẩu hiện tại không đúng';
        _isSuccess = false;
      });
      return;
    }

    // Cập nhật mật khẩu mới
    final result = await db.updatePassword(widget.userId, oldPass, newPass);

    if (result > 0) {
      setState(() {
        _message = 'Đổi mật khẩu thành công!';
        _isSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đổi mật khẩu thành công")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() {
        _message = 'Có lỗi xảy ra khi cập nhật mật khẩu';
        _isSuccess = false;
      });
    }
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

        return StatefulBuilder(builder: (context, setModalState) {
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  onChanged: (v) => setModalState(() => tmpLength = v.round()),
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
                    _newPasswordController.text = newPass;
                    _confirmPasswordController.text = newPass;
                    _checkPasswordStrength(newPass);
                    Clipboard.setData(ClipboardData(text: newPass));
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
                  child: const Text('Generate & Use'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        });
      },
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
                Icon(Icons.lock, color: Colors.white, size: 80),
                SizedBox(height: 10),
                Text(
                  'Đổi mật khẩu',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
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
                  topRight: Radius.circular(30.0),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Mật khẩu hiện tại',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.grey[200],
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscureCurrent = !_obscureCurrent;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Nhập mật khẩu hiện tại' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Mật khẩu mới',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.grey[200],
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _obscureNew
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNew = !_obscureNew;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  String newPass = _generatePassword(
                                    length: _genLength,
                                    alpha: _alphaOption,
                                    nonAlpha: _nonAlphaOption,
                                  );
                                  _newPasswordController.text = newPass;
                                  _confirmPasswordController.text = newPass;
                                  _checkPasswordStrength(newPass);
                                  Clipboard.setData(ClipboardData(text: newPass));
                                },
                              ),
                            ],
                          ),
                        ),
                        onChanged: (value) => _checkPasswordStrength(value),
                        validator: (value) => value!.isEmpty ? 'Nhập mật khẩu mới' : null,
                      ),
                      const SizedBox(height: 8),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Strength: $_passwordStrengthLabel",
                              style: TextStyle(
                                color: _passwordStrength >= 0.75
                                    ? Colors.green
                                    : _passwordStrength >= 0.5
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _openGeneratorDialog,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
                            child: const Text('Password Generator'),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Xác nhận mật khẩu mới',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.grey[200],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Nhập lại mật khẩu mới' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_message.isNotEmpty)
                        Text(
                          _message,
                          style: TextStyle(color: _isSuccess ? Colors.green : Colors.red),
                          textAlign: TextAlign.center,
                        )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
