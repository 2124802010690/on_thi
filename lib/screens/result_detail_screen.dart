import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; // ⚠️ CẦN THÊM IMPORT NÀY

import '../models/question.dart';
import '../models/result_model.dart';

// ------------------------------------------------------------------
// ⭐ CLASS GEMINI SERVICE (Tận dụng code của bạn) ⭐
// ------------------------------------------------------------------
class GeminiService {
  // ⚠️ LƯU Ý: HÃY THAY API KEY NÀY BẰNG KEY THẬT CỦA BẠN TRƯỚC KHI CHẠY
  final String apiKey = "AIzaSyDpZYnoKNJONB3CdmYdZyVxaDFwrM4LcYM"; 
  final String model = "gemini-2.5-flash"; 

  final List<String> _blacklist = [
    'chính trị', 
    'bạo lực', 
    'tài chính', 
    'tuyệt mật',
  ];

  String? _checkBlacklist(String message) {
    final lowerCaseMessage = message.toLowerCase();
    for (var keyword in _blacklist) {
      if (lowerCaseMessage.contains(keyword)) {
        return "Nội dung của bạn chứa từ khóa bị cấm: '$keyword'. Vui lòng sửa lại.";
      }
    }
    return null;
  }

  Future<String> sendMessage(String message) async {
    final blacklistError = _checkBlacklist(message);
    if (blacklistError != null) {
      return blacklistError;
    }
    
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey",
    );
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message}
              ]
            }
          ],
          "generationConfig": { 
            "temperature": 0.7
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data["candidates"] as List?;
        if (candidates != null && candidates.isNotEmpty && data["candidates"][0]["content"] != null) {
          final text = data["candidates"][0]["content"]["parts"][0]["text"];
          return text ?? "Không thể trích xuất nội dung.";
        }
        if (data["promptFeedback"] != null && data["promptFeedback"]["blockReason"] != null) {
          return "Lỗi: Câu hỏi đã bị chặn bởi bộ lọc nội dung (Reason: ${data["promptFeedback"]["blockReason"]}).";
        }
        return "Lỗi: Phản hồi không có nội dung hợp lệ.";
      } else {
        return "Lỗi API (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}
// ------------------------------------------------------------------

class ResultDetailScreen extends StatefulWidget {
  final ResultModel result;
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
  int _currentIndex = 0;
  bool isGridVisible = true;
  
  // ⭐ BIẾN MỚI CHO TÍNH NĂNG AI ⭐
  final GeminiService _geminiService = GeminiService(); 
  String? _aiExplanation;
  bool _isLoadingAI = false;
  // ------------------------------------

  @override
  void initState() {
    super.initState();

    // Parse JSON đáp án
    try {
      final dynamic decodedDynamic = json.decode(widget.result.answers);
      final decoded = decodedDynamic is Map
          ? Map<String, dynamic>.from(decodedDynamic)
          : <String, dynamic>{};
      userAnswers = decoded.map(
        (key, value) => MapEntry(int.tryParse(key.toString()) ?? -1, value.toString()),
      )..removeWhere((k, v) => k == -1);
    } catch (e) {
      debugPrint("! Lỗi parse result.answers: $e");
      userAnswers = {};
    }

    // Lọc câu hỏi đã thi và sắp xếp theo order
    Set<int> requiredIds = {};
    List<int> orderedIds = [];
    if (widget.result.questionIds != null && widget.result.questionIds!.isNotEmpty) {
      orderedIds = widget.result.questionIds!
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      requiredIds = orderedIds.toSet();
    } else {
      requiredIds = userAnswers.keys.toSet();
      orderedIds = requiredIds.toList();
    }

    examQuestions = widget.allQuestions
        .where((q) => requiredIds.contains(q.id))
        .where((q) => q.content.isNotEmpty)
        .toList();

    examQuestions.sort((a, b) => orderedIds.indexOf(a.id).compareTo(orderedIds.indexOf(b.id)));

    _currentIndex = examQuestions.isEmpty ? -1 : 0;
  }

  // ⭐ HÀM MỚI: Reset trạng thái AI khi chuyển câu hỏi ⭐
  void _resetAIState() {
    _aiExplanation = null;
    _isLoadingAI = false;
  }
  
  // Cập nhật hàm điều hướng để reset trạng thái AI
  void _goToNextQuestion() {
    if (_currentIndex < examQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _resetAIState();
      });
    }
  }

  void _goToPreviousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _resetAIState();
      });
    }
  }

  // ⭐ HÀM MỚI: GỌI API GEMINI ⭐
  void _fetchAIExplanation(Question question) async {
    if (_isLoadingAI) return;

    setState(() {
      _isLoadingAI = true;
      _aiExplanation = null;
    });

    // Xây dựng prompt
    String prompt = "Giải thích ngắn gọn (tối đa 4 câu) lý do tại sao đáp án ${question.ansright} là đúng cho câu hỏi sau. Chỉ dùng kiến thức chuyên ngành. Nội dung:\n\n";
    prompt += "Câu hỏi: ${question.content}\n";
    prompt += "A: ${question.ansa}\n";
    prompt += "B: ${question.ansb}\n";
    if (question.ansc.isNotEmpty) prompt += "C: ${question.ansc}\n";
    if (question.ansd.isNotEmpty) prompt += "D: ${question.ansd}\n";
    prompt += "Đáp án đúng là ${question.ansright}. Hãy giải thích chi tiết, ngắn gọn:";

    String result = await _geminiService.sendMessage(prompt);

    setState(() {
      _aiExplanation = result;
      _isLoadingAI = false;
    });
  }
  // ------------------------------------

  Widget _buildAnswerOption(String label, String text, Question question, String? userAnswer) {
    if (text.isEmpty) return const SizedBox.shrink();

    final isCorrectAnswer = label == question.ansright;
    final isUserSelected = userAnswer == label;
    final isUserIncorrect = isUserSelected && !isCorrectAnswer;

    Color color;
    IconData? icon;
    if (isCorrectAnswer) {
      color = Colors.green.shade700;
      icon = Icons.check_circle_outline;
    } else if (isUserIncorrect) {
      color = Colors.red.shade700;
      icon = Icons.cancel_outlined;
    } else {
      color = Colors.black87;
      icon = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: icon != null ? Icon(icon, color: color, size: 22) : null),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label. $text',
              style: TextStyle(color: color, fontSize: 12, height: 1.4), // Font size 12
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final userAnswer = userAnswers[question.id];
    final isUserAnswered = userAnswer != null && userAnswer.isNotEmpty;
    final isCorrect = isUserAnswered && (userAnswer == question.ansright);
    final hasStarError = question.mandatory && !isCorrect && isUserAnswered;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần Tiêu đề/Trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Câu ${_currentIndex + 1}/${examQuestions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF003366))),
              if (isUserAnswered)
                Text(
                  isCorrect ? 'ĐÚNG' : 'SAI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 10),
          
          // Nội dung Câu hỏi
          Text(question.content, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.5)),
          
          // Câu điểm liệt
          if (question.mandatory)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.star, color: hasStarError ? Colors.red.shade700 : Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text('(Câu điểm liệt)',
                      style: TextStyle(
                        color: hasStarError ? Colors.red.shade700 : Colors.red,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      )),
                  if (hasStarError)
                    const Text(' - SAI ĐIỂM LIỆT!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          
          // Hình ảnh
          if (question.image != null && question.image!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.asset(question.image!),
            ),
            
          // Đáp án
          _buildAnswerOption('A', question.ansa, question, userAnswer),
          _buildAnswerOption('B', question.ansb, question, userAnswer),
          if (question.ansc.isNotEmpty) _buildAnswerOption('C', question.ansc, question, userAnswer),
          if (question.ansd.isNotEmpty) _buildAnswerOption('D', question.ansd, question, userAnswer),

          // ------------------------------------------------------------------
          // ⭐ PHẦN HIỂN THỊ GIẢI ĐÁP AI ⭐
          // ------------------------------------------------------------------
          const SizedBox(height: 15),
          const Divider(height: 1, thickness: 1, color: Colors.blueGrey),
          const SizedBox(height: 15),
          
          if (_isLoadingAI)
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('AI đang giải thích...', style: TextStyle(color: Color(0xFF003366), fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          else if (_aiExplanation != null) ...[
            // Kết quả giải thích đã có
            Row(
              children: [
                const Icon(Icons.auto_fix_high, color: Color(0xFF003366), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Giải thích từ Gemini AI:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF003366)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _aiExplanation!,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800, height: 1.5),
            ),
          ] else 
            // Nút để kích hoạt AI
            Center(
              child: TextButton.icon(
                onPressed: () => _fetchAIExplanation(question),
                icon: const Icon(Icons.lightbulb_outline, size: 20),
                label: const Text('Giải thích đáp án (AI)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF003366),
                ),
              ),
            ),
          // ------------------------------------------------------------------
        ],
      ),
    );
  }

  // --- HÀM XÂY DỰNG LƯỚI (Giữ nguyên) ---
  Widget _buildQuestionGrid() {
    final int rows = (examQuestions.length / 8).ceil(); // Đã sửa từ 6 lên 8 để phù hợp với GridView 8 cột
    final double gridHeight = rows * 36.0 + 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => isGridVisible = !isGridVisible),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Danh sách câu hỏi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Icon(isGridVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isGridVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Container(
                height: gridHeight < 170 ? gridHeight : 170,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: rows > 5 ? null : const NeverScrollableScrollPhysics(),
                  itemCount: examQuestions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final question = examQuestions[index];
                    final userAnswer = userAnswers[question.id];
                    final isAnswered = userAnswer != null && userAnswer.isNotEmpty;
                    final isCorrect = isAnswered && userAnswer == question.ansright;

                    Color bg;
                    Color txt;
                    if (index == _currentIndex) {
                      bg = const Color(0xFF003366);
                      txt = Colors.white;
                    } else if (isAnswered) {
                      bg = isCorrect ? Colors.green.shade500 : Colors.red.shade400;
                      txt = Colors.white;
                    } else {
                      bg = Colors.grey.shade300;
                      txt = Colors.black87;
                    }

                    return GestureDetector(
                      onTap: () => setState(() {
                        _currentIndex = index;
                        _resetAIState(); // Reset trạng thái AI khi chuyển câu hỏi
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                          border: index == _currentIndex ? Border.all(color: Colors.lightBlue, width: 2) : null,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: txt, fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (examQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF003366),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003366),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: const Text("Chi tiết bài thi", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text("⚠️ Không có dữ liệu câu hỏi để hiển thị.", style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      );
    }

    final currentQuestion = examQuestions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Chi tiết bài thi", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildQuestionGrid(),
          Expanded(child: SingleChildScrollView(child: _buildQuestionCard(currentQuestion))),
          // Thanh điều hướng (Giữ nguyên)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0 ? _goToPreviousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Trước', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: _currentIndex < examQuestions.length - 1 ? _goToNextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tiếp', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}