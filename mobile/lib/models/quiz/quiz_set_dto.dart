import 'package:freezed_annotation/freezed_annotation.dart';

import 'cached_quiz_set.dart';

part 'quiz_set_dto.freezed.dart';
part 'quiz_set_dto.g.dart';

@freezed
class QuizSetDto with _$QuizSetDto {
  const QuizSetDto._();

  const factory QuizSetDto({
    required String id,
    required String title,
    @Default('') String description,
    @JsonKey(name: 'cohort_id') @Default('') String cohortId,
    @JsonKey(name: 'question_count') @Default(0) int questionCount,
    @JsonKey(name: 'time_limit_seconds') int? timeLimitSeconds,
    @JsonKey(name: 'show_correct_answers')
    @Default(true)
    bool showCorrectAnswers,
    @JsonKey(name: 'available_from') required DateTime availableFrom,
    @JsonKey(name: 'available_until') DateTime? availableUntil,
    @Default('available') String status,
    @Default(false) bool isInProgress,
  }) = _QuizSetDto;

  factory QuizSetDto.fromJson(Map<String, dynamic> json) =>
      _$QuizSetDtoFromJson(json);

  factory QuizSetDto.fromCached(CachedQuizSet cached) => QuizSetDto(
        id: cached.serverId,
        title: cached.title,
        description: cached.description,
        cohortId: cached.cohortId,
        questionCount: cached.questionCount,
        timeLimitSeconds: cached.timeLimitMinutes == null
            ? null
            : cached.timeLimitMinutes! * 60,
        showCorrectAnswers: cached.showCorrectAnswers,
        availableFrom:
            cached.availableFrom ?? DateTime.fromMillisecondsSinceEpoch(0),
        availableUntil: cached.availableUntil,
      );

  bool get isAvailable =>
      status == 'available' && availableFrom.isBefore(DateTime.now());

  bool get isExpired =>
      availableUntil != null && availableUntil!.isBefore(DateTime.now());

  CachedQuizSet toCached() {
    return CachedQuizSet(
      serverId: id,
      title: title,
      description: description,
      cohortId: cohortId,
      questionCount: questionCount,
      timeLimitMinutes:
          timeLimitSeconds == null ? null : (timeLimitSeconds! / 60).ceil(),
      showCorrectAnswers: showCorrectAnswers,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      cachedAt: DateTime.now(),
    );
  }
}
