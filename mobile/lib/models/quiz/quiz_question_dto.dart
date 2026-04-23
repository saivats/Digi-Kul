import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_question_dto.freezed.dart';
part 'quiz_question_dto.g.dart';

@freezed
class QuizQuestionDto with _$QuizQuestionDto {
  const factory QuizQuestionDto({
    required String id,
    @JsonKey(name: 'quiz_set_id') required String quizSetId,
    required String question,
    @JsonKey(name: 'question_type') @Default('mcq') String questionType,
    required List<String> options,
    @JsonKey(name: 'correct_answer') String? correctAnswer,
    @JsonKey(name: 'order_index') @Default(0) int orderIndex,
  }) = _QuizQuestionDto;

  factory QuizQuestionDto.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionDtoFromJson(json);
}
