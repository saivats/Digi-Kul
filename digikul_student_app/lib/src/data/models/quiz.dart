import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quiz.g.dart';

/// Quiz model representing assessment questions
@JsonSerializable()
class Quiz extends Equatable {

  const Quiz({
    required this.id,
    required this.lectureId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.createdAt,
    this.isActive = true,
    this.lectureTitle,
    this.teacherName,
    this.userResponse,
    this.isCorrect,
    this.hasAnswered,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);
  final String id;
  @JsonKey(name: 'lecture_id')
  final String lectureId;
  final String question;
  final List<String> options;
  @JsonKey(name: 'correct_answer')
  final String correctAnswer;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional fields from API responses
  @JsonKey(name: 'lecture_title')
  final String? lectureTitle;
  @JsonKey(name: 'teacher_name')
  final String? teacherName;
  @JsonKey(name: 'user_response')
  final String? userResponse;
  @JsonKey(name: 'is_correct')
  final bool? isCorrect;
  @JsonKey(name: 'has_answered')
  final bool? hasAnswered;

  Map<String, dynamic> toJson() => _$QuizToJson(this);

  Quiz copyWith({
    String? id,
    String? lectureId,
    String? question,
    List<String>? options,
    String? correctAnswer,
    DateTime? createdAt,
    bool? isActive,
    String? lectureTitle,
    String? teacherName,
    String? userResponse,
    bool? isCorrect,
    bool? hasAnswered,
  }) {
    return Quiz(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      lectureTitle: lectureTitle ?? this.lectureTitle,
      teacherName: teacherName ?? this.teacherName,
      userResponse: userResponse ?? this.userResponse,
      isCorrect: isCorrect ?? this.isCorrect,
      hasAnswered: hasAnswered ?? this.hasAnswered,
    );
  }

  /// Check if the user has answered this quiz
  bool get isAnswered => hasAnswered ?? false || userResponse != null;

  /// Get the index of the correct answer
  int get correctAnswerIndex {
    return options.indexOf(correctAnswer);
  }

  /// Get the index of the user's response
  int? get userResponseIndex {
    if (userResponse == null) return null;
    return options.indexOf(userResponse!);
  }

  @override
  List<Object?> get props => [
        id,
        lectureId,
        question,
        options,
        correctAnswer,
        createdAt,
        isActive,
        lectureTitle,
        teacherName,
        userResponse,
        isCorrect,
        hasAnswered,
      ];

  @override
  String toString() {
    return 'Quiz{id: $id, question: $question, options: ${options.length}}';
  }
}

/// Quiz response model
@JsonSerializable()
class QuizResponse extends Equatable {

  const QuizResponse({
    required this.id,
    required this.studentId,
    required this.quizId,
    required this.response,
    required this.isCorrect,
    required this.submittedAt,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizResponseFromJson(json);
  final String id;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'quiz_id')
  final String quizId;
  final String response;
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  @JsonKey(name: 'submitted_at')
  final DateTime submittedAt;

  Map<String, dynamic> toJson() => _$QuizResponseToJson(this);

  @override
  List<Object?> get props => [
        id,
        studentId,
        quizId,
        response,
        isCorrect,
        submittedAt,
      ];
}

/// Request to submit a quiz answer
@JsonSerializable()
class QuizSubmissionRequest extends Equatable {

  const QuizSubmissionRequest({
    required this.response,
  });

  factory QuizSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      _$QuizSubmissionRequestFromJson(json);
  final String response;

  Map<String, dynamic> toJson() => _$QuizSubmissionRequestToJson(this);

  @override
  List<Object?> get props => [response];
}

/// Quiz submission response
@JsonSerializable()
class QuizSubmissionResponse extends Equatable {

  const QuizSubmissionResponse({
    required this.success,
    required this.message,
    this.isCorrect,
    this.correctAnswer,
    this.responseId,
  });

  factory QuizSubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizSubmissionResponseFromJson(json);
  final bool success;
  final String message;
  @JsonKey(name: 'is_correct')
  final bool? isCorrect;
  @JsonKey(name: 'correct_answer')
  final String? correctAnswer;
  @JsonKey(name: 'response_id')
  final String? responseId;

  Map<String, dynamic> toJson() => _$QuizSubmissionResponseToJson(this);

  @override
  List<Object?> get props => [
        success,
        message,
        isCorrect,
        correctAnswer,
        responseId,
      ];
}

/// Quiz summary for list views
@JsonSerializable()
class QuizSummary extends Equatable {

  const QuizSummary({
    required this.id,
    required this.question,
    required this.optionCount,
    this.lectureTitle,
    this.teacherName,
    required this.createdAt,
    this.hasAnswered = false,
    this.isCorrect,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) =>
      _$QuizSummaryFromJson(json);

  factory QuizSummary.fromQuiz(Quiz quiz) {
    return QuizSummary(
      id: quiz.id,
      question: quiz.question,
      optionCount: quiz.options.length,
      lectureTitle: quiz.lectureTitle,
      teacherName: quiz.teacherName,
      createdAt: quiz.createdAt,
      hasAnswered: quiz.isAnswered,
      isCorrect: quiz.isCorrect,
    );
  }
  final String id;
  final String question;
  final int optionCount;
  final String? lectureTitle;
  final String? teacherName;
  final DateTime createdAt;
  final bool hasAnswered;
  final bool? isCorrect;

  Map<String, dynamic> toJson() => _$QuizSummaryToJson(this);

  /// Get truncated question for display
  String get truncatedQuestion {
    if (question.length <= 100) return question;
    return '${question.substring(0, 97)}...';
  }

  /// Get result status
  String get resultStatus {
    if (!hasAnswered) return 'Not answered';
    if (isCorrect ?? false) return 'Correct';
    if (isCorrect == false) return 'Incorrect';
    return 'Submitted';
  }

  @override
  List<Object?> get props => [
        id,
        question,
        optionCount,
        lectureTitle,
        teacherName,
        createdAt,
        hasAnswered,
        isCorrect,
      ];
}

/// Quiz results and statistics
@JsonSerializable()
class QuizResults extends Equatable {

  const QuizResults({
    required this.quizId,
    required this.question,
    required this.correctAnswer,
    required this.totalResponses,
    required this.correctResponses,
    required this.accuracyPercentage,
    required this.results,
  });

  factory QuizResults.fromJson(Map<String, dynamic> json) =>
      _$QuizResultsFromJson(json);
  @JsonKey(name: 'quiz_id')
  final String quizId;
  final String question;
  @JsonKey(name: 'correct_answer')
  final String correctAnswer;
  @JsonKey(name: 'total_responses')
  final int totalResponses;
  @JsonKey(name: 'correct_responses')
  final int correctResponses;
  @JsonKey(name: 'accuracy_percentage')
  final double accuracyPercentage;
  final List<QuizOptionResult> results;

  Map<String, dynamic> toJson() => _$QuizResultsToJson(this);

  /// Get formatted accuracy percentage
  String get formattedAccuracy {
    return '${accuracyPercentage.toStringAsFixed(1)}%';
  }

  @override
  List<Object?> get props => [
        quizId,
        question,
        correctAnswer,
        totalResponses,
        correctResponses,
        accuracyPercentage,
        results,
      ];
}

/// Individual quiz option result
@JsonSerializable()
class QuizOptionResult extends Equatable {

  const QuizOptionResult({
    required this.option,
    required this.responses,
    required this.percentage,
    required this.isCorrect,
  });

  factory QuizOptionResult.fromJson(Map<String, dynamic> json) =>
      _$QuizOptionResultFromJson(json);
  final String option;
  final int responses;
  final double percentage;
  @JsonKey(name: 'is_correct')
  final bool isCorrect;

  Map<String, dynamic> toJson() => _$QuizOptionResultToJson(this);

  /// Get formatted percentage
  String get formattedPercentage {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Get formatted response count
  String get formattedResponses {
    if (responses == 1) return '1 response';
    return '$responses responses';
  }

  @override
  List<Object?> get props => [option, responses, percentage, isCorrect];
}
