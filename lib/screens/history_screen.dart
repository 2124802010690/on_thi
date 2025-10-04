import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/question.dart';
import '../models/result_model.dart';
import '../models/user_model.dart';
import 'result_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final UserModel user; // ✅ nhận user từ HomePage

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ResultModel> _results = []; // ✅ chuẩn model
  List<Question> _allQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbHelper = DBHelper();
    final results = await dbHelper.getResultsByUserId(widget.user.id!); // List<ResultModel>
    final allQuestions = await dbHelper.getAllQuestions();

    setState(() {
      _results = results;
      _allQuestions = allQuestions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366), // nền xanh hải quân
      body: SafeArea(
        child: Column(
          children: [
            // Header có nút quay về
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Lịch sử thi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Nội dung
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              'Bạn chưa thực hiện bài thi nào.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final result = _results[index];
                              final takenAt = DateTime.parse(result.takenAt);
                              final resultText =
                                  result.passed == 1 ? 'ĐẠT' : 'TRƯỢT';
                              final resultColor =
                                  result.passed == 1 ? Colors.green : Colors.red;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor:
                                        resultColor.withOpacity(0.1),
                                    child: Icon(
                                      result.passed == 1
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: resultColor,
                                      size: 28,
                                    ),
                                  ),
                                  title: Text(
                                    'Bài thi ngày ${takenAt.day}/${takenAt.month}/${takenAt.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Điểm: ${result.score}/${result.total}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: Text(
                                    resultText,
                                    style: TextStyle(
                                      color: resultColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ResultDetailScreen(
                                          result: result, // ✅ truyền ResultModel
                                          allQuestions: _allQuestions,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
