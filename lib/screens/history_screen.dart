import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/question.dart';
import 'result_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _results = [];
  List<Question> _allQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbHelper = DBHelper();
    final results = await dbHelper.getResultsByUserId(1); 
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
      appBar: AppBar(
        title: const Text('Lịch sử bài thi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('Bạn chưa thực hiện bài thi nào.'))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final takenAt = DateTime.parse(result['taken_at']);
                    final resultText = result['passed'] == 1 ? 'ĐẠT' : 'TRƯỢT';
                    final resultColor = result['passed'] == 1 ? Colors.green : Colors.red;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(
                          result['passed'] == 1 ? Icons.check_circle : Icons.cancel,
                          color: resultColor,
                          size: 30,
                        ),
                        title: Text(
                          'Bài thi ngày ${takenAt.day}/${takenAt.month}/${takenAt.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          'Điểm số: ${result['score']}/${result['total']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Text(
                          resultText,
                          style: TextStyle(
                            color: resultColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultDetailScreen(
                                result: result,
                                allQuestions: _allQuestions, // Truyền danh sách câu hỏi
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}