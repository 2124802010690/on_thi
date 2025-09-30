// lib/screens/quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/db_helper.dart';
import 'result_screen.dart';
import 'dart:convert';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Timer _timer;
  Duration remaining = const Duration(minutes: 20);
  int currentIndex = 0;
  Map<int, String> answers = {};
  bool isGridVisible = true;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (remaining.inSeconds <= 1) {
          _timer.cancel();
          finishExam(auto: true);
        } else {
          remaining = remaining - const Duration(seconds: 1);
        }
      });
    });
  }

  void selectAnswer(int index, String choice) {
    setState(() {
      answers[index] = choice;
    });
  }

  void finishExam({bool auto = false}) async {
    // Ngừng bộ đếm thời gian
    _timer.cancel();

    int correct = 0;
    bool failedMandatory = false;

    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final selected = answers[i];
      if (selected != null && selected == q.ansright) {
        correct++;
      }
      // Kiểm tra câu hỏi điểm liệt
      if (q.mandatory && (selected == null || selected != q.ansright)) {
        failedMandatory = true;
      }
    }

    final passed = (!failedMandatory) && (correct >= 28);
    Map<String, String> stringAnswers = answers.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    // Lưu kết quả vào cơ sở dữ liệu
    try {
      await DBHelper().insertResult({
        'user_id': 1, // Bạn có thể thay đổi user_id tùy theo logic ứng dụng
        'score': correct,
        'total': widget.questions.length,
        'passed': passed ? 1 : 0,
        'failed_due_mandatory': failedMandatory ? 1 : 0,
        'taken_at': DateTime.now().toIso8601String(),
        'answers': json.encode(stringAnswers),
      });
    } catch (e) {
      debugPrint('Lỗi khi lưu kết quả: $e');
    }

    if (!mounted) {
      return;
    }

    // Điều hướng sang màn hình kết quả và thay thế màn hình hiện tại
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          questions: widget.questions,
          answers: answers,
          isPassed: passed,
          correctCount: correct,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget choiceButton(int qIndex, String label, String text) {
    final sel = answers[qIndex];
    bool selected = sel == label;
    return GestureDetector(
      onTap: () => selectAnswer(qIndex, label),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.blue : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              '$label. ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.blue : Colors.black,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? Colors.blue : Colors.black,
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
    final q = widget.questions[currentIndex];
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1), // nền xanh giống login
      appBar: AppBar(
        toolbarHeight: 40,
        title: const Text(
          'Bài thi lý thuyết',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              finishExam(); // Bấm "Nộp bài" trên AppBar sẽ kết thúc bài thi
            },
            child: const Text(
              'Nộp bài',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Câu: ${currentIndex + 1}/${widget.questions.length}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Thời gian: $minutes:$seconds',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              isGridVisible = !isGridVisible;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Danh sách câu hỏi',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Icon(isGridVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: isGridVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          firstChild: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: widget.questions.length,
                            itemBuilder: (context, index) {
                              Color color = Colors.grey[300]!;
                              if (answers.containsKey(index)) {
                                color = Colors.blue.shade200;
                              }
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentIndex = index;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: currentIndex == index ? Border.all(color: Colors.blue, width: 2) : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (index + 1).toString(),
                                      style: TextStyle(
                                        color: currentIndex == index ? Colors.blue : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Hiển thị nội dung câu hỏi và hình ảnh (nếu có)
                  Text(q.content, style: const TextStyle(fontSize: 15)),
                  if (q.image != null && q.image!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Image.asset(q.image!),
                    ),
                  const SizedBox(height: 14),
                  // Hiển thị các lựa chọn trả lời
                  if (q.ansa.isNotEmpty) choiceButton(currentIndex, 'A', q.ansa),
                  if (q.ansb.isNotEmpty) choiceButton(currentIndex, 'B', q.ansb),
                  if (q.ansc.isNotEmpty) choiceButton(currentIndex, 'C', q.ansc),
                  if (q.ansd.isNotEmpty) choiceButton(currentIndex, 'D', q.ansd),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: currentIndex > 0
                            ? () {
                                setState(() => currentIndex--);
                              }
                            : null,
                        child: const Text('Trước'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (currentIndex < widget.questions.length - 1) {
                            setState(() => currentIndex++);
                          } else {
                            // Nút "Tiếp" chuyển thành "Nộp bài" ở câu hỏi cuối cùng
                            finishExam();
                          }
                        },
                        child: Text(currentIndex < widget.questions.length - 1 ? 'Tiếp' : 'Nộp bài'),
                      )
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
}