import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/attendance_repository.dart';
import '../../../widgets/digikul_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/skeleton_loader.dart';
import '../widgets/attendance_list.dart';
import '../widgets/attendance_stats_row.dart';
import '../widgets/attendance_warning_card.dart';
import '../widgets/attendance_week_strip.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceProvider);
    final summaryAsync = ref.watch(attendanceSummaryProvider);

    return Scaffold(
      appBar: const DigikulAppBar(title: 'Attendance'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceProvider);
          ref.invalidate(attendanceSummaryProvider);
        },
        child: attendanceAsync.when(
          loading: () => ListView(
            children: const [
              SizedBox(height: 16),
              SkeletonStatsRow(),
              SizedBox(height: 16),
              SkeletonBanner(),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SkeletonListLoader(itemCount: 5),
              ),
            ],
          ),
          error: (e, _) => ListView(
            children: [
              AppErrorWidget(
                message: e.toString(),
                onRetry: () {
                  ref.invalidate(attendanceProvider);
                  ref.invalidate(attendanceSummaryProvider);
                },
              ),
            ],
          ),
          data: (records) {
            if (records.isEmpty) {
              return ListView(
                children: const [
                  EmptyState(
                    title: 'No attendance records',
                    subtitle: 'Attendance will appear here after your first class',
                    icon: Icons.calendar_today_rounded,
                  ),
                ],
              );
            }

            return ListView(
              children: [
                const SizedBox(height: 16),
                summaryAsync.when(
                  loading: () => const SkeletonStatsRow(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (summary) => Column(
                    children: [
                      AttendanceStatsRow(summary: summary),
                      const SizedBox(height: 12),
                      AttendanceWarningCard(summary: summary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AttendanceWeekStrip(records: records),
                const SizedBox(height: 16),
                AttendanceList(records: records),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}
