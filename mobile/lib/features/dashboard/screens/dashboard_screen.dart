import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/material/material_dto.dart';
import '../../../providers/pending_sync_provider.dart';
import '../../../repositories/attendance_repository.dart';
import '../../../repositories/lecture_repository.dart';
import '../../../repositories/material_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../materials/widgets/material_type_icon.dart';
import '../widgets/live_lecture_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/upcoming_lecture_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(liveLectureProvider);
          ref.invalidate(upcomingLecturesProvider);
          ref.invalidate(materialsProvider);
          ref.invalidate(attendanceSummaryProvider);
          ref.invalidate(pendingSyncCountProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            _HeroHeader(),
            SizedBox(height: 16),
            _StatsRow(),
            SizedBox(height: 20),
            _UpcomingSection(),
            SizedBox(height: 20),
            _RecentMaterialsSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Indigo header: greeting + the live banner (if any). The banner sits
/// inside the header so it is the first thing on screen when a class is on.
class _HeroHeader extends ConsumerWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(liveLectureProvider);
    final name = (PreferencesService.studentName ?? 'there').split(' ').first;
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(today,
                        style: AppTextStyles.bodySmall(
                            color: const Color(0xFFC7CBE8))),
                    const SizedBox(height: 2),
                    Text('Hi, $name',
                        style: AppTextStyles.headlineMedium(color: Colors.white)
                            .copyWith(fontSize: 22)),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Text(initial,
                      style: AppTextStyles.titleMedium(color: Colors.white)),
                ),
              ),
            ],
          ),
          liveAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (lecture) => lecture == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LiveLectureBanner(
                      lecture: lecture,
                      margin: EdgeInsets.zero,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceSummaryProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    final materials = ref.watch(materialsProvider);
    final online = ref.watch(connectivityProvider).isOnline;

    final attendanceText = attendance.maybeWhen(
      data: (s) => '${s.percentage.round()}%',
      orElse: () => '—',
    );
    final attendanceColor = attendance.maybeWhen(
      data: (s) => s.isBelowThreshold ? AppColors.live : AppColors.textPrimary,
      orElse: () => AppColors.textPrimary,
    );
    final pendingCount = pending.maybeWhen(data: (n) => n, orElse: () => 0);
    final savedCount = materials.maybeWhen(
      data: (list) => list.where((m) => m.isDownloaded).length,
      orElse: () => 0,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Attendance',
                  value: attendanceText,
                  valueColor: attendanceColor,
                  onTap: () => context.go('/attendance'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Quizzes',
                  value: pendingCount > 0 ? '$pendingCount pending' : 'Open',
                  onTap: () => context.go('/quiz'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Saved files',
                  value: '$savedCount',
                  onTap: () => context.go('/materials'),
                ),
              ),
            ],
          ),
        ),
        if (!online || pendingCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.offlineSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.offline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !online
                          ? 'Offline — showing saved data.${pendingCount > 0 ? ' $pendingCount quiz will sync when you\'re back.' : ''}'
                          : '$pendingCount quiz answer${pendingCount == 1 ? '' : 's'} waiting to sync.',
                      style: AppTextStyles.labelMedium(color: AppColors.offline)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.labelSmall(color: AppColors.textSecondary)
                      .copyWith(fontSize: 11)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: AppTextStyles.stat(
                        color: valueColor ?? AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingSection extends ConsumerWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingLecturesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Upcoming classes'),
        upcomingAsync.when(
          loading: () => const SkeletonHorizontalCards(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(upcomingLecturesProvider),
            ),
          ),
          data: (lectures) {
            if (lectures.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: EmptyState(
                  title: 'No upcoming classes',
                  subtitle: 'Your teacher hasn\'t scheduled the next class yet',
                  icon: Icons.event_available_rounded,
                ),
              );
            }
            return SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: lectures.length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) =>
                    UpcomingLectureCard(lecture: lectures[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentMaterialsSection extends ConsumerWidget {
  const _RecentMaterialsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent materials',
          onSeeAll: () => context.go('/materials'),
        ),
        materialsAsync.when(
          loading: () => const SkeletonListLoader(itemCount: 3),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(materialsProvider),
            ),
          ),
          data: (materials) {
            if (materials.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: EmptyState(
                  title: 'No materials yet',
                  subtitle: 'Your teacher hasn\'t uploaded any materials',
                  icon: Icons.folder_open_rounded,
                ),
              );
            }
            final recent = materials.take(5).toList();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, index) =>
                    _RecentMaterialTile(material: recent[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentMaterialTile extends StatelessWidget {
  const _RecentMaterialTile({required this.material});

  final MaterialDto material;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: MaterialTypeIcon(fileType: material.fileType),
      title: Text(
        material.title,
        style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          material.fileType.toUpperCase(),
          material.fileSizeFormatted,
          if (material.uploadedBy.isNotEmpty) material.uploadedBy,
        ].join(' · '),
        style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
      ),
      trailing: material.isDownloaded
          ? const Icon(Icons.offline_pin_rounded, color: AppColors.online, size: 20)
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      // Opens the material detail (download / open) — the old tap only
      // showed the upload date in a snackbar.
      onTap: () => context.go('/materials/${material.id}'),
    );
  }
}
