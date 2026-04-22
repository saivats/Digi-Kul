import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/attendance/attendance_dto.dart';

class AttendanceList extends StatelessWidget {
  const AttendanceList({super.key, required this.records});

  final List<AttendanceDto> records;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = [...records]
      ..sort((a, b) => b.lectureDate.compareTo(a.lectureDate));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final record = sorted[index];
        final dateLabel = DateFormat('MMM d, yyyy').format(record.lectureDate);
        final statusColor = record.isPresent ? AppColors.success : AppColors.error;
        final statusLabel = record.status[0].toUpperCase() +
            record.status.substring(1);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              record.isPresent
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          title: Text(
            record.lectureTitle,
            style: AppTextStyles.titleMedium(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            dateLabel,
            style: AppTextStyles.caption(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: AppTextStyles.labelSmall(color: statusColor),
            ),
          ),
        );
      },
    );
  }
}
