import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyDpZYnoKNJONB3CdmYdZyVxaDFwrM4LcYM";
  final String model = "gemini-2.5-flash"; 

  Future<String> sendMessage(String message) async {
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
        // ✅ ĐÃ SỬA: Đổi tên trường từ "config" thành "generationConfig"
        "generationConfig": { // <-- ĐÂY LÀ TÊN CHÍNH XÁC MÀ API CẦN
          "temperature": 0.7
        }
      }),
    );

    // ... (Phần xử lý response status code 200/else giữ nguyên)
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