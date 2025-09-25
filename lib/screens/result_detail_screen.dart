// lib/screens/result_detail_screen.dart
import 'package:flutter/material.dart';

class ResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final List<Map<String, dynamic>> resultDetails;

  const ResultDetailScreen({
    Key? key,
    required this.result,
    required this.resultDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final passed = result['passed'] == 1;
    final takenAtStr = (result['taken_at'] ?? '').toString();
    DateTime? takenAt;
    try {
      takenAt =
          takenAtStr.isNotEmpty ? DateTime.parse(takenAtStr) : null;
    } catch (_) {
      takenAt = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        title: const Text("Chi tiết bài thi"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.cancel,
                    color: passed ? Colors.greenAccent : Colors.redAccent,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả: ${passed ? "ĐẠT" : "TRƯỢT"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          takenAt != null
                              ? 'Ngày: ${takenAt.day}/${takenAt.month}/${takenAt.year}'
                              : 'Ngày: -',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
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
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                ),
                child: resultDetails.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Không tìm thấy chi tiết bài thi.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: resultDetails.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final d = resultDetails[index];
                          final content = (d['content'] ?? '').toString();
                          final img = (d['image'] ?? '').toString();
                          final userAnswer =
                              (d['user_answer'] ?? '').toString();
                          final correct =
                              (d['ansright'] ?? '').toString();

                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Câu ${index + 1}: $content',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (img.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Image.asset(
                                        img,
                                        errorBuilder: (c, e, s) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  _buildOption(
                                      "A",
                                      (d['ansa'] ?? '').toString(),
                                      userAnswer,
                                      correct),
                                  _buildOption(
                                      "B",
                                      (d['ansb'] ?? '').toString(),
                                      userAnswer,
                                      correct),
                                  if (((d['ansc'] ?? '').toString())
                                      .isNotEmpty)
                                    _buildOption(
                                        "C",
                                        (d['ansc'] ?? '').toString(),
                                        userAnswer,
                                        correct),
                                  if (((d['ansd'] ?? '').toString())
                                      .isNotEmpty)
                                    _buildOption(
                                        "D",
                                        (d['ansd'] ?? '').toString(),
                                        userAnswer,
                                        correct),
                                ],
                              ),
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

  Widget _buildOption(
      String label, String text, String userAnswer, String correctAnswer) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final isCorrect = label == correctAnswer;
    final isUser = userAnswer == label;

    Color color = Colors.black87;
    IconData? icon;
    if (isUser) {
      color = isCorrect ? Colors.green : Colors.red;
      icon = isCorrect ? Icons.check_circle : Icons.close;
    } else if (isCorrect) {
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: color, size: 20),
          if (icon != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label. $text',
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
