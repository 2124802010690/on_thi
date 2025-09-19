import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/db_helper.dart';

class TheoryScreen extends StatefulWidget {
  final int topicId;
  final String topicTitle;

  const TheoryScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheoryQuestions();
  }

  Future<void> _loadTheoryQuestions() async {
    try {
      final rawQuestions = await DBHelper().getQuestionsByTopicId(widget.topicId);
      setState(() {
        _questions = rawQuestions.map((map) => Question.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading theory questions: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải câu hỏi lý thuyết')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('Không có câu hỏi nào trong chương này.'))
              : ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Câu ${index + 1}: ${question.content}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (question.image != null && question.image!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Image.asset(
                                  question.image!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 8),

                            // Hiển thị các câu trả lời
                            if (question.ansa != null && question.ansa.isNotEmpty)
                              _buildAnswerOption('A', question.ansa, question.ansright),
                            if (question.ansb != null && question.ansb.isNotEmpty)
                              _buildAnswerOption('B', question.ansb, question.ansright),
                            if (question.ansc != null && question.ansc.isNotEmpty)
                              _buildAnswerOption('C', question.ansc, question.ansright),
                            if (question.ansd != null && question.ansd.isNotEmpty)
                              _buildAnswerOption('D', question.ansd, question.ansright),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildAnswerOption(String option, String text, String correctOption) {
    bool isCorrect = option == correctOption;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$option. $text',
        style: TextStyle(
          fontSize: 14,
          color: isCorrect ? Colors.green : Colors.black,
          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}