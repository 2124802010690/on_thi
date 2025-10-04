import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyDpZYnoKNJONB3CdmYdZyVxaDFwrM4LcYM";
  final String model = "gemini-2.5-flash"; 

  // Danh sách các từ khóa bị cấm (Blacklist)
  final List<String> _blacklist = [
    'chính trị', 
    'bạo lực', 
    'tài chính', 
    'tuyệt mật',
    // Thêm các từ khóa khác nếu cần
  ];

  // Hàm kiểm tra từ khóa bị cấm
  String? _checkBlacklist(String message) {
    final lowerCaseMessage = message.toLowerCase();
    for (var keyword in _blacklist) {
      if (lowerCaseMessage.contains(keyword)) {
        return "Nội dung của bạn chứa từ khóa bị cấm: '$keyword'. Vui lòng sửa lại.";
      }
    }
    return null; // Trả về null nếu không có từ khóa nào bị cấm
  }

  Future<String> sendMessage(String message) async {
    // ⚠️ BƯỚC 1: KIỂM TRA BLACKLIST
    final blacklistError = _checkBlacklist(message);
    if (blacklistError != null) {
      return blacklistError; // Trả về thông báo lỗi nếu bị cấm
    }
    // ------------------------------------
    
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey",
    );
    
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
      if (candidates != null && candidates.isNotEmpty) {
        final text = candidates[0]["content"]["parts"][0]["text"];
        return text ?? "Không thể trích xuất nội dung.";
      }
      return "Lỗi: Phản hồi không có nội dung.";
    } else {
      return "Lỗi API (${response.statusCode}): ${response.body}";
    }
  }
}