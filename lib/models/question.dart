class Question {
  final int id;
  final String content;
  final String? image;
  final String ansa;
  final String ansb;
  final String ansc;
  final String ansd;
  final String ansright;
  final bool mandatory;

  Question({
    required this.id,
    required this.content,
    this.image,
    required this.ansa,
    required this.ansb,
    required this.ansc,
    required this.ansd,
    required this.ansright,
    required this.mandatory,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int,
      content: (map['content'] ?? '') as String,
      image: map['image'] as String?,  // cho phép null
      ansa: (map['ansa'] ?? '') as String,
      ansb: (map['ansb'] ?? '') as String,
      ansc: (map['ansc'] ?? '') as String,
      ansd: (map['ansd'] ?? '') as String,
      ansright: (map['ansright'] ?? '') as String,
      mandatory: (map['mandatory'] ?? 0) == 1,
    );
  }
}
