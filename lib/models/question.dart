class Question {
  int? id;
  int topicId;
  String title;        // 👈 thêm
  String content;
  String? image;       // 👈 thêm (có thể null)
  String ansa, ansb, ansc, ansd, ansright;
  String? anshint;     // 👈 thêm
  bool mandatory;

  Question({
    this.id,
    required this.topicId,
    required this.title,     // 👈 constructor thêm
    required this.content,
    this.image,
    required this.ansa,
    required this.ansb,
    required this.ansc,
    required this.ansd,
    required this.ansright,
    this.anshint,
    this.mandatory = false,
  });

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        id: m['id'] as int?,
        topicId: m['topic_id'] as int,
        title: m['title'] as String? ?? '',          // 👈 lấy title
        content: m['content'] as String? ?? '',
        image: m['image'] as String?,                // 👈 lấy image (nullable)
        ansa: m['ansa'] as String? ?? '',
        ansb: m['ansb'] as String? ?? '',
        ansc: m['ansc'] as String? ?? '',
        ansd: m['ansd'] as String? ?? '',
        ansright: m['ansright'] as String? ?? '',
        anshint: m['anshint'] as String?,            // 👈 lấy hint
        mandatory: (m['mandatory'] as int? ?? 0) == 1,
      );
}
