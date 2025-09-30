// lib/screens/result_detail_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/question.dart';

class ResultDetailScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final List<Question> allQuestions;

  const ResultDetailScreen({
    super.key,
    required this.result,
    required this.allQuestions,
  });

  @override
  State<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends State<ResultDetailScreen> {
  late Map<int, String> userAnswers;
  late List<Question> examQuestions;

  @override
  void initState() {
    super.initState();
    try {
      // decode đáp án đã làm: {"1":"A","2":"C",...}
      final decodedAnswers = json.decode(widget.result['answers']);
      userAnswers = decodedAnswers.map(
        (key, value) => MapEntry(int.parse(key), value.toString()),
      );
    } catch (e) {
      userAnswers = {};
    }

    // Lấy ra danh sách câu hỏi của bài thi (dựa theo id có trong userAnswers)
    examQuestions = widget.allQuestions
        .where((q) => userAnswers.keys.contains(q.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366), // nền xanh hải quân
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: const [
                  Icon(Icons.assignment, color: Colors.white, size: 70),
                  SizedBox(height: 10),
                  Text(
                    'Chi tiết bài thi',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung chi tiết
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tổng quan kết quả
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kết quả: ${widget.result['passed'] == 1 ? 'ĐẠT' : 'TRƯỢT'}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: widget.result['passed'] == 1
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ngày thi: ${DateTime.parse(widget.result['taken_at']).day}/${DateTime.parse(widget.result['taken_at']).month}/${DateTime.parse(widget.result['taken_at']).year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Điểm số: ${widget.result['score']}/${widget.result['total']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Text(
                        'Chi tiết các câu hỏi:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Danh sách câu hỏi trong bài thi (chỉ 30 câu đã làm)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: examQuestions.length,
                        itemBuilder: (context, index) {
                          final question = examQuestions[index];
                          final userAnswer = userAnswers[question.id];
                          return _buildQuestionCard(
                              question, index, userAnswer);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị từng câu hỏi
  Widget _buildQuestionCard(
      Question question, int index, String? userAnswer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu ${index + 1}: ${question.content}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (question.mandatory)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.red, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '(Câu điểm liệt)',
                      style: TextStyle(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            if (question.image != null && question.image!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Image.asset(question.image!),
              ),
            _buildAnswerOption(
                'A', question.ansa, userAnswer, question.ansright),
            _buildAnswerOption(
                'B', question.ansb, userAnswer, question.ansright),
            if (question.ansc.isNotEmpty)
              _buildAnswerOption(
                  'C', question.ansc, userAnswer, question.ansright),
            if (question.ansd.isNotEmpty)
              _buildAnswerOption(
                  'D', question.ansd, userAnswer, question.ansright),
          ],
        ),
      ),
    );
  }

  /// Hiển thị từng đáp án
  Widget _buildAnswerOption(
    String label,
    String text,
    String? userAnswer,
    String correctAnswer,
  ) {
    if (text.isEmpty) return const SizedBox.shrink();

    final isCorrectAnswer = label == correctAnswer;
    final isUserSelected = userAnswer == label;

    Color color = Colors.black;
    IconData? icon;

    if (isUserSelected) {
      color = isCorrectAnswer ? Colors.green : Colors.red;
      icon = isCorrectAnswer ? Icons.check_circle_outline : Icons.close;
    } else if (isCorrectAnswer) {
      color = Colors.green;
      icon = Icons.check_circle_outline;
    } else {
      color = Colors.black54;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label. $text',
              style: TextStyle(
                color: color,
                fontWeight:
                    isCorrectAnswer ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
