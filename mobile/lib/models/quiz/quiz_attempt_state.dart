import 'package:freezed_annotation/freezed_annotation.dart';

import 'quiz_question_dto.dart';
import 'quiz_result_dto.dart';
import 'quiz_set_dto.dart';

part 'quiz_attempt_state.freezed.dart';

enum QuizAttemptPhase { loading, active, submitting, submitted, queued, error }

@freezed
class QuizAttemptState with _$QuizAttemptState {
  const factory QuizAttemptState({
    @Default(QuizAttemptPhase.loading) QuizAttemptPhase phase,
    QuizSetDto? quizSet,
    @Default(<QuizQuestionDto>[]) List<QuizQuestionDto> questions,
    @Default(<String, String>{}) Map<String, String> answers,
    String? attemptId,
    @Default(0) int currentQuestionIndex,
    int? remainingSeconds,
    QuizResultDto? result,
    String? errorMessage,
    @Default(false) bool isOffline,
  }) = _QuizAttemptState;
}
