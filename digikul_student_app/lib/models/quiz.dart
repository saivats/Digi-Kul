class Quiz {
  final String id;
  final String lectureId;
  final String question;
  final List<String> options;
  // The correct answer is not sent to the student to prevent cheating.
  // It's handled by the backend.
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.lectureId,
    required this.question,
    required this.options,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      lectureId: json['lecture_id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}