// lib/models/topic.dart
class Topic {
  final int id;
  final String title;
  final String description;
  final int pos; // thứ tự hiển thị (nếu có)

  Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.pos,
  });

  // helper parse int an toàn
  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    // Hỗ trợ nhiều tên cột khác nhau (title/name, description/desc)
    final title = (map['title'] ?? map['name'] ?? map['topic_title'] ?? '').toString();
    final description = (map['description'] ?? map['desc'] ?? map['topic_description'] ?? '').toString();
    final id = _parseInt(map['id'] ?? map['topic_id']);
    final pos = _parseInt(map['pos'] ?? map['position'] ?? map['order'] ?? 0);

    return Topic(
      id: id,
      title: title,
      description: description,
      pos: pos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pos': pos,
    };
  }
}
