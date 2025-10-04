class ResultModel {
  final int? id;
  final int userId;
  final int score;
  final int total;
  final bool passed;
  final bool failedDueMandatory;
  final String takenAt; // ISO string
  final String answers; // JSON string
  final String? questionIds; // ✅ thêm cột này

  ResultModel({
    this.id,
    required this.userId,
    required this.score,
    required this.total,
    required this.passed,
    required this.failedDueMandatory,
    required this.takenAt,
    required this.answers,
    this.questionIds,
  });

  factory ResultModel.fromMap(Map<String, dynamic> map) {
    return ResultModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      score: map['score'] as int,
      total: map['total'] as int,
      passed: (map['passed'] as int) == 1,
      failedDueMandatory: (map['failed_due_mandatory'] as int) == 1,
      takenAt: map['taken_at'] as String,
      answers: map['answers'] as String,
      questionIds: map['question_ids'] as String?, // ✅ thêm
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'score': score,
      'total': total,
      'passed': passed ? 1 : 0,
      'failed_due_mandatory': failedDueMandatory ? 1 : 0,
      'taken_at': takenAt,
      'answers': answers,
      'question_ids': questionIds, // ✅ thêm
    };
  }
}
