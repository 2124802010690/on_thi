import 'package:flutter/material.dart';
import '../services/gemini_service.dart'; // Đảm bảo đường dẫn này đúng

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _chatService = GeminiService(); 
  final ScrollController _scrollController = ScrollController(); 

  List<Map<String, String>> messages = [];
  bool _isLoading = false;
  // Biến trạng thái để kiểm soát hiển thị danh sách gợi ý trong AlertDialog
  // bool _isSuggestionListVisible = false; // Không cần nữa vì ta dùng AlertDialog

  final List<String> _suggestions = [
    "Giải thích về câu điểm liệt là gì?",
    "Các biển báo cấm quan trọng nhất?",
    "Quy tắc vượt xe đúng cách?",
    "Nên học phần lý thuyết nào trước?",
    "Hỏi về xe ưu tiên?",
    "Thế nào là vạch liền, vạch đứt?",
    "Tốc độ tối đa trong khu dân cư?",
  ];

  @override
  void initState() {
    super.initState();
    messages.add({
      "role": "assistant",
      "content": "Chào bạn! Tôi là Chatbot ôn thi GPLX. Hãy hỏi tôi bất cứ điều gì về Luật Giao thông Đường bộ Việt Nam để ôn thi giấy phép lái xe nhé!"
    });
  }

  // Cập nhật hàm gửi tin nhắn
  Future<void> _sendMessage({String? suggestionText}) async {
    final text = suggestionText ?? _controller.text.trim();
    if (text.isEmpty) return;
    
    // Đóng dialog nếu tin nhắn được gửi từ dialog
    if (suggestionText != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); 
    }

    // 1. Cập nhật UI: Thêm tin nhắn người dùng, xóa input, bật loading
    setState(() {
      messages.add({"role": "user", "content": text});
      _controller.clear();
      _isLoading = true;
    });

    // 2. Cuộn xuống cuối
    _scrollToBottom();
    
    // 3. Gọi API Gemini
    final reply = await _chatService.sendMessage(text);

    // 4. Cập nhật UI: Thêm tin nhắn trả lời, tắt loading
    setState(() {
      messages.add({"role": "assistant", "content": reply});
      _isLoading = false;
    });

    // 5. Cuộn xuống cuối lần nữa
    _scrollToBottom();
  }
  
  // Hàm cuộn xuống cuối danh sách
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ⭐ HÀM MỚI: HIỂN THỊ DANH SÁCH CÂU HỎI GỢI Ý DƯỚI DẠNG DIALOG ⭐
  void _showSuggestionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('💡 Gợi ý câu hỏi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 0, left: 15, right: 15),
          content: SingleChildScrollView(
            child: ListBody(
              children: _suggestions.map((suggestion) {
                return InkWell(
                  onTap: () {
                    // Gửi tin nhắn và đóng dialog
                    _sendMessage(suggestionText: suggestion);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '• $suggestion',
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // WIDGET MỚI: ITEM CHAT (Giữ nguyên)
  Widget _buildChatItem(Map<String, String> msg, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF003366) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Text(
          msg["content"] ?? "",
          style: TextStyle(
            fontSize: 15,
            color: isUser ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ta giữ lại thanh gợi ý dưới khung chat khi mới vào để tăng khả năng tương tác
    final bool showInitialChips = messages.length <= 2;
    
    return Scaffold(
      backgroundColor: const Color(0xFF003366), 
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ⭐ CẬP NHẬT HEADER: Thêm nút gợi ý ⭐
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Ta căn chỉnh lại để có vị trí đẹp hơn
                  const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text(
                    "Chatbot Ôn Thi GPLX",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // ⭐ NÚT GỢI Ý MỚI ⭐
                  IconButton(
                    icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                    onPressed: () => _showSuggestionDialog(context),
                    tooltip: 'Gợi ý câu hỏi',
                  ),
                  
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Khung nội dung chat
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Giữ lại thanh gợi ý dưới khung chat khi mới vào (tùy chọn)
                    if (showInitialChips) _buildSuggestionChips(), 
                    
                    // Khu vực chat
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isUser = msg["role"] == "user";
                          return _buildChatItem(msg, isUser);
                        },
                      ),
                    ),

                    if (_isLoading)
                      const LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                      ),

                    // Ô nhập tin nhắn
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: "Nhập câu hỏi...",
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          CircleAvatar(
                            backgroundColor: const Color(0xFF003366),
                            radius: 24,
                            child: IconButton(
                              icon: const Icon(Icons.send,
                                  color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET DÒNG GỢI Ý DƯỚI KHUNG CHAT (Giữ nguyên)
  Widget _buildSuggestionChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(suggestion, style: const TextStyle(fontSize: 13, color: Color(0xFF003366))),
              backgroundColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              onPressed: () => _sendMessage(suggestionText: suggestion),
            ),
          );
        },
      ),
    );
  }
}