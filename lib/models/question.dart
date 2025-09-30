
class Question {
  final int id;
  final String title;
  final String content;
  final String? image;
  final String ansa;
  final String ansb;
  final String ansc;
  final String ansd;
  final String ansright;
  final bool mandatory;
  final int topicId;
  final int pos;

  Question({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.ansa,
    required this.ansb,
    required this.ansc,
    required this.ansd,
    required this.ansright,
    required this.mandatory,
    required this.topicId,
    required this.pos,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  static String _toStr(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: _toInt(map['id']),
      title: _toStr(map['title']),
      content: _toStr(map['content']),
      image: map['image'] == null ? null : _toStr(map['image']),
      ansa: _toStr(map['ansa']),
      ansb: _toStr(map['ansb']),
      ansc: _toStr(map['ansc']),
      ansd: _toStr(map['ansd']),
      ansright: _toStr(map['ansright']),
      mandatory: _toInt(map['mandatory']) == 1,
      topicId: _toInt(map['topic_id']),
      pos: _toInt(map['pos']),
    );
  }


}
