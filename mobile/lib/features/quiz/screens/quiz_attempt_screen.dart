import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/quiz/quiz_attempt_state.dart';
import '../../../providers/quiz_attempt_provider.dart';

class QuizAttemptScreen extends ConsumerWidget {
  const QuizAttemptScreen({
    super.key,
    required this.quizSetId,
  });

  final String quizSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptState = ref.watch(quizAttemptProvider(quizSetId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitConfirmation(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            attemptState.quizSet?.title ?? 'Quiz',
            style: AppTextStyles.titleLarge(),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(context, ref),
          ),
          actions: [
            if (attemptState.remainingSeconds != null)
              _TimerBadge(seconds: attemptState.remainingSeconds!),
          ],
        ),
        body: switch (attemptState.phase) {
          QuizAttemptPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          QuizAttemptPhase.active || QuizAttemptPhase.submitting => _QuizBody(
              state: attemptState,
              quizSetId: quizSetId,
            ),
          QuizAttemptPhase.submitted => _SubmittedView(
              quizSetId: quizSetId,
              attemptId: attemptState.attemptId!,
            ),
          QuizAttemptPhase.queued => _QueuedView(quizSetId: quizSetId),
          QuizAttemptPhase.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    attemptState.errorMessage ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Quiz?'),
        content: const Text(
          'Your progress will be lost if you leave now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final isLow = seconds < 60;

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: isLow ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: AppTextStyles.titleMedium(
              color: isLow ? AppColors.error : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizBody extends ConsumerWidget {
  const _QuizBody({
    required this.state,
    required this.quizSetId,
  });

  final QuizAttemptState state;
  final String quizSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.questions[state.currentQuestionIndex];
    final notifier = ref.read(quizAttemptProvider(quizSetId).notifier);
    final selectedAnswer = state.answers[question.id];
    final isSubmitting = state.phase == QuizAttemptPhase.submitting;

    return Column(
      children: [
        LinearProgressIndicator(
          value: (state.currentQuestionIndex + 1) / state.questions.length,
          backgroundColor: AppColors.divider,
          color: AppColors.primary,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${state.currentQuestionIndex + 1} of ${state.questions.length}',
                  style: AppTextStyles.labelMedium(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  style: AppTextStyles.headlineSmall(),
                ),
                const SizedBox(height: 24),
                ...question.options.map((option) => _OptionTile(
                      option: option,
                      isSelected: selectedAnswer == option,
                      onTap: isSubmitting
                          ? null
                          : () => notifier.selectAnswer(question.id, option),
                    )),
              ],
            ),
          ),
        ),
        _NavigationBar(
          state: state,
          quizSetId: quizSetId,
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    this.onTap,
  });

  final String option;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: AppTextStyles.bodyMedium(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationBar extends ConsumerWidget {
  const _NavigationBar({
    required this.state,
    required this.quizSetId,
  });

  final QuizAttemptState state;
  final String quizSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(quizAttemptProvider(quizSetId).notifier);
    final isFirst = state.currentQuestionIndex == 0;
    final isLast = state.currentQuestionIndex == state.questions.length - 1;
    final isSubmitting = state.phase == QuizAttemptPhase.submitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton.icon(
              onPressed:
                  isSubmitting ? null : () => notifier.previousQuestion(),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Previous'),
            ),
          const Spacer(),
          if (isLast)
            ElevatedButton(
              onPressed: isSubmitting ? null : () => notifier.submitQuiz(),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Quiz'),
            )
          else
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : () => notifier.nextQuestion(),
              icon: const Text('Next'),
              label: const Icon(Icons.chevron_right, size: 18),
            ),
        ],
      ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({
    required this.quizSetId,
    required this.attemptId,
  });

  final String quizSetId;
  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text('Quiz Submitted!', style: AppTextStyles.headlineLarge()),
            const SizedBox(height: 8),
            Text(
              'Your answers have been recorded.',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/quiz/$quizSetId/result/$attemptId'),
              child: const Text('View Results'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/quiz'),
              child: const Text('Back to Quizzes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuedView extends StatelessWidget {
  const _QueuedView({required this.quizSetId});

  final String quizSetId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            Text('Saved Offline', style: AppTextStyles.headlineLarge()),
            const SizedBox(height: 8),
            Text(
              'Your quiz will be submitted automatically when you reconnect to the internet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/quiz'),
              child: const Text('Back to Quizzes'),
            ),
          ],
        ),
      ),
    );
  }
}
