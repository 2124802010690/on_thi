import 'package:flutter/material.dart';
import '../models/question.dart';

class ResultScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, String> answers;
  final bool isPassed;
  final int correctCount;

  const ResultScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.isPassed,
    required this.correctCount,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int currentIndex = 0;
  bool isGridVisible = true; // Biến trạng thái để ẩn/hiện khung câu hỏi

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kết quả bài thi'),
        ),
        body: const Center(
          child: Text('Không có dữ liệu câu hỏi.'),
        ),
      );
    }

    final currentQuestion = widget.questions[currentIndex];
    final userAnswer = widget.answers[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả bài thi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Đúng: ${widget.correctCount}/${widget.questions.length}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Bạn đã thi ${widget.isPassed ? 'đạt!' : 'rớt!'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isPassed ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Khung danh sách câu hỏi
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        padding: const EdgeInsets.all(8.0),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: widget.questions.length,
                        itemBuilder: (context, index) {
                          Color color;
                          String? userAnswer = widget.answers[index];
                          String correctAnswer = widget.questions[index].ansright;
                          bool isMandatory = widget.questions[index].mandatory;

                          if (userAnswer == null) {
                            color = Colors.grey[300]!; // Chưa trả lời
                          } else if (userAnswer == correctAnswer) {
                            color = Colors.green.shade200; // Đúng
                          } else {
                            color = Colors.red.shade200; // Sai
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
                                child: Row( // Sử dụng Row để đặt số và dấu sao cạnh nhau
                                  mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung trong Row
                                  mainAxisSize: MainAxisSize.min, // Đảm bảo Row chỉ chiếm không gian cần thiết
                                  children: [
                                    Text(
                                      (index + 1).toString(),
                                      style: TextStyle(
                                        color: currentIndex == index ? Colors.blue : Colors.black87, // Thay đổi màu số khi được chọn
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14, // Cỡ chữ cho số câu hỏi
                                      ),
                                    ),
                                    if (isMandatory)
                                      const Text(
                                        ' ★', // Dấu sao lớn hơn
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16, // Cỡ chữ lớn hơn cho dấu sao
                                        ),
                                      ),
                                  ],
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
              const SizedBox(height: 20),
              // Khung câu hỏi chi tiết
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu ${currentIndex + 1}/${widget.questions.length}: ${currentQuestion.content}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Cỡ chữ cho nội dung câu hỏi
                    ),
                    if (currentQuestion.mandatory)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          '* (Câu điểm liệt)',
                          style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 14), // Cỡ chữ cho chú thích điểm liệt
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (currentQuestion.image != null && currentQuestion.image!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Image.asset(currentQuestion.image!),
                      ),
                    _buildAnswerOption('A', currentQuestion.ansa, userAnswer, currentQuestion.ansright),
                    _buildAnswerOption('B', currentQuestion.ansb, userAnswer, currentQuestion.ansright),
                    _buildAnswerOption('C', currentQuestion.ansc, userAnswer, currentQuestion.ansright),
                    _buildAnswerOption('D', currentQuestion.ansd, userAnswer, currentQuestion.ansright),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                    onPressed: currentIndex < widget.questions.length - 1
                        ? () {
                            setState(() => currentIndex++);
                          }
                        : null,
                    child: const Text('Tiếp'),
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Quay về trang chính', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(String label, String text, String? userAnswer, String correctAnswer) {
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink(); // Widget rỗng
    }
    Color color = Colors.black;
    FontWeight fontWeight = FontWeight.normal;
    IconData? icon;

    final isCorrectAnswer = label == correctAnswer;
    final isUserSelected = userAnswer == label;

    if (isUserSelected) {
      if (isCorrectAnswer) {
        color = Colors.green;
        fontWeight = FontWeight.bold;
        icon = Icons.check_circle_outline;
      } else {
        color = Colors.red;
        icon = Icons.close;
      }
    } else if (isCorrectAnswer) {
      color = Colors.green;
      fontWeight = FontWeight.bold;
      icon = Icons.check_circle_outline;
    }

    return ListTile(
      title: Text(
        '$label. $text',
        style: TextStyle(color: color, fontWeight: fontWeight, fontSize: 16), // Cỡ chữ cho các lựa chọn trả lời
      ),
      leading: Icon(
        icon,
        color: color,
      ),
    );
  }
}