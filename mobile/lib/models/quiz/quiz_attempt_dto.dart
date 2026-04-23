import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_attempt_dto.freezed.dart';
part 'quiz_attempt_dto.g.dart';

@freezed
class QuizAttemptDto with _$QuizAttemptDto {
  const factory QuizAttemptDto({
    required String id,
    @JsonKey(name: 'quiz_set_id') required String quizSetId,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'started_at') required DateTime startedAt,
    @JsonKey(name: 'submitted_at') DateTime? submittedAt,
    @Default('in_progress') String status,
  }) = _QuizAttemptDto;

  factory QuizAttemptDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptDtoFromJson(json);
}
