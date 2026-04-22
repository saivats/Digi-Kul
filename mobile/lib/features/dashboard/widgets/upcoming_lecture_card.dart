import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/lecture/lecture_dto.dart';
import '../../../providers/core_providers.dart';

class UpcomingLectureCard extends ConsumerWidget {
  const UpcomingLectureCard({super.key, required this.lecture});

  final LectureDto lecture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(clockTickProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeUntil = lecture.timeUntilStart;
    final timeLabel = _formatTimeUntil(timeUntil);
    final dateLabel = DateFormat('MMM d, h:mm a').format(lecture.scheduledTime);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.primaryLight, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style: AppTextStyles.labelSmall(
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lecture.title,
              style: AppTextStyles.titleMedium(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              lecture.teacherName,
              style: AppTextStyles.bodySmall(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: AppTextStyles.caption(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeUntil(Duration duration) {
    if (duration.isNegative) return 'Starting soon';
    if (duration.inDays > 0) return 'In ${duration.inDays}d';
    if (duration.inHours > 0) return 'In ${duration.inHours}h';
    if (duration.inMinutes > 0) return 'In ${duration.inMinutes}m';
    return 'Starting now';
  }
}
