import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../services/db_helper.dart';

class TheoryScreen extends StatefulWidget {
  final Topic topic; // ✅ Truyền luôn TopicModel thay vì id + title

  const TheoryScreen({
    super.key,
    required this.topic,
  });

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final Map<int, String> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadTheoryQuestions();
  }

  Future<void> _loadTheoryQuestions() async {
    try {
      final questions = await DBHelper().getQuestionsByTopicId(widget.topic.id); // ✅ DBHelper trả List<Question>
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading theory questions: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải câu hỏi lý thuyết')),
        );
      }
    }
  }

  void _handleAnswerSelection(int questionIndex, String selectedOption) {
    setState(() {
      _selectedAnswers[questionIndex] = selectedOption;
    });
  }

  Widget _buildAnswerOption(
    int questionIndex,
    String option,
    String text,
    String correctOption,
  ) {
    final selectedOption = _selectedAnswers[questionIndex];
    final isAnswered = selectedOption != null;
    final isCorrect = option == correctOption;
    final isSelected = option == selectedOption;

    Color color;
    if (!isAnswered) {
      color = Colors.black;
    } else {
      if (isCorrect) {
        color = Colors.green;
      } else if (isSelected && !isCorrect) {
        color = Colors.red;
      } else {
        color = Colors.black;
      }
    }

    return GestureDetector(
      onTap: !isAnswered ? () => _handleAnswerSelection(questionIndex, option) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected && !isCorrect && isAnswered ? Colors.red.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected && isAnswered ? color : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              '$option. ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _loadingScaffold();
    }

    if (_questions.isEmpty) {
      return _emptyScaffold();
    }

    final currentQuestion = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      appBar: AppBar(
        title: Text(
          widget.topic.title, // ✅ Dùng title từ TopicModel
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Câu ${_currentIndex + 1}: ${currentQuestion.content}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (currentQuestion.image != null && currentQuestion.image!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Image.asset(
                        currentQuestion.image!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 14),

                  if (currentQuestion.ansa.isNotEmpty)
                    _buildAnswerOption(_currentIndex, 'A', currentQuestion.ansa, currentQuestion.ansright),
                  if (currentQuestion.ansb.isNotEmpty)
                    _buildAnswerOption(_currentIndex, 'B', currentQuestion.ansb, currentQuestion.ansright),
                  if (currentQuestion.ansc.isNotEmpty)
                    _buildAnswerOption(_currentIndex, 'C', currentQuestion.ansc, currentQuestion.ansright),
                  if (currentQuestion.ansd.isNotEmpty)
                    _buildAnswerOption(_currentIndex, 'D', currentQuestion.ansd, currentQuestion.ansright),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nút Trước
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _currentIndex > 0
                                ? () => setState(() => _currentIndex--)
                                : null,
                            child: const Text('Trước'),
                          ),
                        ),
                      ),

                      // Nút Tiếp hoặc Quay lại
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: isLastQuestion
                              ? ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Quay lại màn hình chính'),
                                )
                              : ElevatedButton(
                                  onPressed: () => setState(() => _currentIndex++),
                                  child: const Text('Tiếp'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Scaffold _loadingScaffold() => Scaffold(
        backgroundColor: const Color(0xFF003366),
        appBar: AppBar(
          title: const Text('Học lý thuyết', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF003366),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  Scaffold _emptyScaffold() => Scaffold(
        backgroundColor: const Color(0xFF003366),
        appBar: AppBar(
          title: const Text('Học lý thuyết', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF003366),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Không có câu hỏi nào trong chương này.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
