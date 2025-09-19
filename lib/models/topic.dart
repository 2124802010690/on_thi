class Topic {
  final int id;
  final String title;
  final String description;
  final String? featureImg;
  final int? parent;
  final int pos;
  final String status;

  Topic({
    required this.id,
    required this.title,
    required this.description,
    this.featureImg,
    this.parent,
    required this.pos,
    required this.status,
  });

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      featureImg: map['featureimg'],
      parent: map['parent'],
      pos: map['pos'],
      status: map['status'],
    );
  }
}