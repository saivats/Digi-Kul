class Quiz {

  const Quiz({
    required this.id,
    required this.lectureId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.createdAt,
    this.isActive = true,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? '',
      lectureId: json['lecture_id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }
  final String id;
  final String lectureId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lecture_id': lectureId,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Quiz copyWith({
    String? id,
    String? lectureId,
    String? question,
    List<String>? options,
    String? correctAnswer,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Quiz(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quiz && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Quiz{id: $id, question: $question, options: $options}';
  }
}

class QuizResponse {

  const QuizResponse({
    required this.id,
    required this.studentId,
    required this.quizId,
    required this.response,
    this.isCorrect,
    required this.submittedAt,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      quizId: json['quiz_id'] ?? '',
      response: json['response'] ?? '',
      isCorrect: json['is_correct'],
      submittedAt: DateTime.tryParse(json['submitted_at'] ?? '') ?? DateTime.now(),
    );
  }
  final String id;
  final String studentId;
  final String quizId;
  final String response;
  final bool? isCorrect;
  final DateTime submittedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'quiz_id': quizId,
      'response': response,
      'is_correct': isCorrect,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'QuizResponse{id: $id, studentId: $studentId, quizId: $quizId, response: $response, isCorrect: $isCorrect}';
  }
}