import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/material/material_dto.dart';
import '../../../repositories/lecture_repository.dart';
import '../../../repositories/material_repository.dart';
import '../../../widgets/digikul_app_bar.dart';
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
      appBar: const DigikulAppBar(showLogo: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(liveLectureProvider);
          ref.invalidate(upcomingLecturesProvider);
          ref.invalidate(materialsProvider);
        },
        child: ListView(
          children: const [
            SizedBox(height: 8),
            _LiveNowSection(),
            SizedBox(height: 16),
            _UpcomingSection(),
            SizedBox(height: 16),
            _RecentMaterialsSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LiveNowSection extends ConsumerWidget {
  const _LiveNowSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(liveLectureProvider);

    return liveAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (lecture) {
        if (lecture == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '🔴 Live Now'),
            LiveLectureBanner(lecture: lecture),
          ],
        );
      },
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
        SectionHeader(
          title: 'Upcoming Classes',
          onSeeAll: () => context.go('/materials'),
        ),
        upcomingAsync.when(
          loading: () => const SkeletonHorizontalCards(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(upcomingLecturesProvider),
            ),
          ),
          data: (lectures) {
            if (lectures.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: EmptyState(
                  title: 'No upcoming classes',
                  subtitle: 'Check back later for scheduled lectures',
                  icon: Icons.event_available_rounded,
                ),
              );
            }
            return SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
          title: 'Recent Materials',
          onSeeAll: () => context.go('/materials'),
        ),
        materialsAsync.when(
          loading: () => const SkeletonListLoader(itemCount: 3),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(materialsProvider),
            ),
          ),
          data: (materials) {
            if (materials.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: EmptyState(
                  title: 'No materials yet',
                  subtitle: 'Your teacher hasn\'t uploaded any materials',
                  icon: Icons.folder_open_rounded,
                ),
              );
            }
            final recent = materials.take(5).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) =>
                  _RecentMaterialTile(material: recent[index]),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: MaterialTypeIcon(fileType: material.fileType),
      title: Text(
        material.title,
        style: AppTextStyles.titleMedium(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${material.fileSizeFormatted} · ${material.uploadedBy}',
        style: AppTextStyles.bodySmall(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      trailing: material.isDownloaded
          ? const Icon(Icons.offline_pin_rounded, color: AppColors.success, size: 20)
          : null,
      onTap: () {
        if (material.uploadedAt != null) {
          final date = DateFormat.yMMMd().format(material.uploadedAt!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uploaded: $date')),
          );
        }
      },
    );
  }
}
