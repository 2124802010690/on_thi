import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_helper.dart';
import '../models/question.dart';
import 'quiz_screen.dart';
import 'topic_list_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? user; // Cho phép user có thể là null
  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Map<String, dynamic> user;
  bool loading = false;
  final List<String> banners = [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
    'assets/images/banner3.png',
  ];
  late PageController _pageController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Khởi tạo user với dữ liệu từ widget.user hoặc một Map rỗng nếu widget.user là null
    user = widget.user ?? {};
    _loadUserFromSharedPreferences(); // Tải dữ liệu từ SharedPreferences ngay khi màn hình được tạo

    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page!.round() + 1) % banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  // Hàm mới để tải lại thông tin người dùng từ SharedPreferences
  Future<void> _loadUserFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() {
        user = jsonDecode(userData);
      });
    }
  }

  void startExam() async {
    setState(() => loading = true);
    final raw = await DBHelper().getExamQuestions();
    final questions = raw.map((m) => Question.fromMap(m)).toList();
    setState(() => loading = false);

    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lấy câu hỏi. Vui lòng thử lại.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(questions: questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: user),
                          ),
                        );
                        _loadUserFromSharedPreferences();
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: (user['avatar'] != null && File(user['avatar']).existsSync())
                            ? FileImage(File(user['avatar'])) as ImageProvider
                            : const AssetImage("assets/images/avatar.png"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Xin chào, ${user['name'] ?? 'Học viên'} 👋",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(banners[index], fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      children: [
                        _buildActionButton(
                          icon: Icons.menu_book,
                          label: 'Học lý thuyết',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TopicListScreen()),
                            );
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.access_time,
label: 'Thi sát hạch',
                          onTap: startExam,
                          isLoading: loading,
                        ),
                        _buildActionButton(
                          icon: Icons.history,
                          label: 'Lịch sử thi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HistoryScreen()),
                            );
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.person,
                          label: 'Thông tin cá nhân',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
                            );
                            _loadUserFromSharedPreferences();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const CircularProgressIndicator()
                  : Icon(icon, size: 40.0, color: Colors.blue),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}