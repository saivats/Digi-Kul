import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/attendance/attendance_dto.dart';

class AttendanceWeekStrip extends StatelessWidget {
  const AttendanceWeekStrip({super.key, required this.records});

  final List<AttendanceDto> records;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeks = _groupByWeek(records);

    if (weeks.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 90,
      child: PageView.builder(
        itemCount: weeks.length,
        reverse: true,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (context, weekIndex) {
          final weekEntry = weeks[weekIndex];
          final weekLabel = weekEntry.key;
          final weekRecords = weekEntry.value;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekLabel,
                  style: AppTextStyles.labelSmall(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (dayIndex) {
                    final record = weekRecords.length > dayIndex
                        ? weekRecords[dayIndex]
                        : null;
                    final dayLabel = _dayLabel(dayIndex);
                    return _DayDot(
                      label: dayLabel,
                      record: record,
                      isDark: isDark,
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<MapEntry<String, List<AttendanceDto?>>> _groupByWeek(
      List<AttendanceDto> records) {
    if (records.isEmpty) return [];

    final sorted = [...records]
      ..sort((a, b) => b.lectureDate.compareTo(a.lectureDate));

    final Map<String, List<AttendanceDto>> grouped = {};
    for (final record in sorted) {
      final weekStart = record.lectureDate.subtract(
        Duration(days: record.lectureDate.weekday - 1),
      );
      final key = DateFormat('MMM d').format(weekStart);
      grouped.putIfAbsent(key, () => []).add(record);
    }

    return grouped.entries.toList();
  }

  String _dayLabel(int index) {
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.record,
    required this.isDark,
  });

  final String label;
  final AttendanceDto? record;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = record == null
        ? (isDark ? Colors.grey[800]! : AppColors.divider)
        : record!.isPresent
            ? AppColors.success
            : AppColors.error;

    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: record != null
              ? Icon(
                  record!.isPresent
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  size: 14,
                  color: color,
                )
              : null,
        ),
      ],
    );
  }
}
