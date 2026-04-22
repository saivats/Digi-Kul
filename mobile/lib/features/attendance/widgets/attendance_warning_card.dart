import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/attendance/attendance_summary.dart';

class AttendanceWarningCard extends StatelessWidget {
  const AttendanceWarningCard({super.key, required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.isBelowThreshold) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Attendance Warning',
                  style: AppTextStyles.titleMedium(color: AppColors.warning),
                ),
                const SizedBox(height: 2),
                Text(
                  'Attend ${summary.classesNeededFor75} more class${summary.classesNeededFor75 == 1 ? '' : 'es'} to reach 75%',
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
