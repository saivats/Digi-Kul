import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/quiz/quiz_set_dto.dart';
import '../../../providers/pending_sync_provider.dart';
import '../../../repositories/quiz_repository.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';

final _quizSetsProvider = FutureProvider<List<QuizSetDto>>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizSets();
});

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizSets = ref.watch(_quizSetsProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quizzes', style: AppTextStyles.headlineMedium()),
        actions: [
          pendingCount.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Chip(
                      label: Text('$count pending'),
                      backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                      labelStyle: AppTextStyles.labelSmall(
                        color: AppColors.warning,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: quizSets.when(
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No Quizzes Yet',
              subtitle: 'Quizzes will appear here when your teacher posts them.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(_quizSetsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return _QuizCard(quiz: quiz);
              },
            ),
          );
        },
        loading: () => const SkeletonLoader(itemCount: 4),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(_quizSetsProvider),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});

  final QuizSetDto quiz;

  @override
  Widget build(BuildContext context) {
    final isAvailable = quiz.isAvailable && !quiz.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isAvailable
            ? () => context.push('/quiz/${quiz.id}/attempt')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      size: 20,
                      color: isAvailable
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: AppTextStyles.titleLarge(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${quiz.questionCount} questions',
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(quiz: quiz),
                ],
              ),
              if (quiz.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (quiz.timeLimitSeconds != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(quiz.timeLimitSeconds! / 60).ceil()} min',
                      style: AppTextStyles.labelSmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.quiz});

  final QuizSetDto quiz;

  @override
  Widget build(BuildContext context) {
    if (quiz.isExpired) {
      return _buildChip('Expired', AppColors.textSecondary);
    }
    if (quiz.isAvailable) {
      return _buildChip('Available', AppColors.success);
    }
    return _buildChip('Upcoming', AppColors.warning);
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall(color: color),
      ),
    );
  }
}
