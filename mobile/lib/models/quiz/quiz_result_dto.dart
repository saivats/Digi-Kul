import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_result_dto.freezed.dart';
part 'quiz_result_dto.g.dart';

@freezed
class QuizResultDto with _$QuizResultDto {
  const factory QuizResultDto({
    @JsonKey(name: 'attempt_id') required String attemptId,
    @JsonKey(name: 'quiz_set_id') required String quizSetId,
    @JsonKey(name: 'total_questions') @Default(0) int totalQuestions,
    @JsonKey(name: 'correct_answers') @Default(0) int correctAnswers,
    @JsonKey(name: 'score_percentage') @Default(0.0) double scorePercentage,
    @JsonKey(name: 'time_taken_seconds') int? timeTakenSeconds,
    @Default(<QuestionReview>[]) List<QuestionReview> review,
  }) = _QuizResultDto;

  factory QuizResultDto.fromJson(Map<String, dynamic> json) =>
      _$QuizResultDtoFromJson(json);
}

@freezed
class QuestionReview with _$QuestionReview {
  const factory QuestionReview({
    @JsonKey(name: 'question_id') required String questionId,
    required String question,
    required List<String> options,
    @JsonKey(name: 'selected_answer') String? selectedAnswer,
    @JsonKey(name: 'correct_answer') String? correctAnswer,
    @JsonKey(name: 'is_correct') @Default(false) bool isCorrect,
  }) = _QuestionReview;

  factory QuestionReview.fromJson(Map<String, dynamic> json) =>
      _$QuestionReviewFromJson(json);
}
