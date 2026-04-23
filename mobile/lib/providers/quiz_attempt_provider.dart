import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/quiz/quiz_attempt_state.dart';
import '../repositories/quiz_repository.dart';

part 'quiz_attempt_provider.g.dart';

@riverpod
class QuizAttempt extends _$QuizAttempt {
  Timer? _timer;

  @override
  QuizAttemptState build(String quizSetId) {
    ref.onDispose(() {
      _timer?.cancel();
    });
    _initQuiz();
    return const QuizAttemptState();
  }

  Future<void> _initQuiz() async {
    try {
      final repo = ref.read(quizRepositoryProvider);
      final questions = await repo.getQuestions(quizSetId);

      if (questions.isEmpty) {
        state = state.copyWith(
          phase: QuizAttemptPhase.error,
          errorMessage: 'No questions found for this quiz.',
        );
        return;
      }

      final attempt = await repo.startAttempt(quizSetId);

      state = state.copyWith(
        phase: QuizAttemptPhase.active,
        questions: questions,
        attemptId: attempt.id,
        currentQuestionIndex: 0,
      );

      final quizSets = await repo.getQuizSets();
      final matchingSet = quizSets.where((s) => s.id == quizSetId).firstOrNull;

      if (matchingSet != null) {
        state = state.copyWith(quizSet: matchingSet);

        if (matchingSet.timeLimitSeconds != null) {
          state = state.copyWith(
            remainingSeconds: matchingSet.timeLimitSeconds,
          );
          _startTimer();
        }
      }
    } catch (e) {
      state = state.copyWith(
        phase: QuizAttemptPhase.error,
        errorMessage: 'Failed to load quiz: $e',
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingSeconds;
      if (remaining == null) return;

      if (remaining <= 1) {
        _timer?.cancel();
        submitQuiz();
      } else {
        state = state.copyWith(remainingSeconds: remaining - 1);
      }
    });
  }

  void selectAnswer(String questionId, String answer) {
    if (state.phase != QuizAttemptPhase.active) return;
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers[questionId] = answer;
    state = state.copyWith(answers: updatedAnswers);
  }

  void goToQuestion(int index) {
    if (index < 0 || index >= state.questions.length) return;
    state = state.copyWith(currentQuestionIndex: index);
  }

  void nextQuestion() {
    goToQuestion(state.currentQuestionIndex + 1);
  }

  void previousQuestion() {
    goToQuestion(state.currentQuestionIndex - 1);
  }

  Future<void> submitQuiz() async {
    if (state.phase == QuizAttemptPhase.submitting) return;
    _timer?.cancel();

    state = state.copyWith(phase: QuizAttemptPhase.submitting);

    try {
      final repo = ref.read(quizRepositoryProvider);
      final result = await repo.submitAttempt(
        attemptId: state.attemptId!,
        answers: state.answers,
        quizSetId: quizSetId,
      );

      if (result != null) {
        state = state.copyWith(
          phase: QuizAttemptPhase.submitted,
          result: result,
        );
      } else {
        state = state.copyWith(
          phase: QuizAttemptPhase.queued,
          isOffline: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        phase: QuizAttemptPhase.error,
        errorMessage: 'Failed to submit quiz: $e',
      );
    }
  }

  bool get allQuestionsAnswered =>
      state.answers.length == state.questions.length;
}
