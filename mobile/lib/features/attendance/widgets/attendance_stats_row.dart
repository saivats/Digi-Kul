import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/attendance/attendance_summary.dart';

class AttendanceStatsRow extends StatelessWidget {
  const AttendanceStatsRow({super.key, required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            label: 'Total',
            value: '${summary.totalClasses}',
            color: AppColors.info,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Present',
            value: '${summary.presentClasses}',
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Percentage',
            value: '${summary.percentage.toStringAsFixed(1)}%',
            color: summary.isBelowThreshold ? AppColors.error : AppColors.success,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headlineMedium(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
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
}
