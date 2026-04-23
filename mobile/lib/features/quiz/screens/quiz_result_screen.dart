import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/quiz/quiz_result_dto.dart';
import '../../../repositories/quiz_repository.dart';
import '../../shared/widgets/app_error_widget.dart';

final _quizResultProvider =
    FutureProvider.family<QuizResultDto, String>((ref, attemptId) {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getResult(attemptId);
});

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({
    super.key,
    required this.quizSetId,
    required this.attemptId,
  });

  final String quizSetId;
  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(_quizResultProvider(attemptId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Results', style: AppTextStyles.headlineMedium()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/quiz'),
        ),
      ),
      body: result.when(
        data: (data) => _ResultContent(result: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(_quizResultProvider(attemptId)),
        ),
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.result});

  final QuizResultDto result;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ScoreCard(result: result),
          const SizedBox(height: 24),
          if (result.review.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Review', style: AppTextStyles.headlineSmall()),
            ),
            const SizedBox(height: 12),
            ...result.review.asMap().entries.map(
                  (entry) => _ReviewCard(
                    index: entry.key + 1,
                    review: entry.value,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final QuizResultDto result;

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.scorePercentage >= 75
        ? AppColors.success
        : result.scorePercentage >= 50
            ? AppColors.warning
            : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: result.scorePercentage / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.divider,
                    color: scoreColor,
                  ),
                  Center(
                    child: Text(
                      '${result.scorePercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.displayLarge(color: scoreColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${result.correctAnswers} of ${result.totalQuestions} correct',
              style: AppTextStyles.titleLarge(),
            ),
            if (result.timeTakenSeconds != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed in ${(result.timeTakenSeconds! / 60).ceil()} min',
                style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.review,
  });

  final int index;
  final QuestionReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: review.isCorrect
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  child: Icon(
                    review.isCorrect ? Icons.check : Icons.close,
                    size: 16,
                    color: review.isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Q$index: ${review.question}',
                    style: AppTextStyles.titleMedium(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...review.options.map((option) {
              final isSelected = option == review.selectedAnswer;
              final isCorrect = option == review.correctAnswer;

              Color? bgColor;
              Color? borderColor;
              if (isCorrect) {
                bgColor = AppColors.success.withValues(alpha: 0.08);
                borderColor = AppColors.success;
              } else if (isSelected && !isCorrect) {
                bgColor = AppColors.error.withValues(alpha: 0.08);
                borderColor = AppColors.error;
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor ?? AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: AppTextStyles.bodyMedium(),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    if (isSelected && !isCorrect)
                      const Icon(Icons.cancel, size: 18, color: AppColors.error),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
