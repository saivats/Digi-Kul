import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/material/material_dto.dart';
import '../../../repositories/material_repository.dart';
import '../../../widgets/digikul_app_bar.dart';
import '../../../widgets/error_widget.dart';
import '../widgets/material_card.dart';
import '../widgets/material_type_icon.dart';

/// Replaces the old "Material Viewer" placeholder route. Download, open
/// with the system viewer, or remove the offline copy.
class MaterialDetailScreen extends ConsumerWidget {
  const MaterialDetailScreen({super.key, required this.materialId});

  final String materialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);
    final progress = ref.watch(downloadProgressProvider)[materialId];

    return Scaffold(
      appBar: DigikulAppBar(
        title: 'Material',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/materials'),
        ),
      ),
      body: materialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(materialsProvider),
        ),
        data: (materials) {
          final material =
              materials.where((m) => m.id == materialId).firstOrNull;
          if (material == null) {
            return const AppErrorWidget(message: 'This material is no longer available.');
          }
          return _Body(material: material, progress: progress);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.material, required this.progress});
  final MaterialDto material;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = [
      material.fileType.toUpperCase(),
      material.fileSizeFormatted,
      if (material.uploadedBy.isNotEmpty) material.uploadedBy,
      if (material.uploadedAt != null) AppDateUtils.formatDate(material.uploadedAt!),
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MaterialTypeIcon(fileType: material.fileType, size: 44),
              const SizedBox(height: 14),
              Text(material.title, style: AppTextStyles.headlineSmall()),
              const SizedBox(height: 6),
              Text(meta, style: AppTextStyles.bodySmall(color: AppColors.textSecondary)),
              if (material.isDownloaded) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded, size: 16, color: AppColors.online),
                    const SizedBox(width: 6),
                    Text('Saved on this phone — works offline',
                        style: AppTextStyles.labelMedium(color: AppColors.online)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (progress != null) ...[
          LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 8),
          Text('Downloading… ${(progress! * 100).toInt()}%',
              style: AppTextStyles.bodySmall(color: AppColors.textSecondary)),
        ] else if (material.isDownloaded) ...[
          ElevatedButton.icon(
            onPressed: () => openMaterialFile(context, material),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(materialRepositoryProvider).deleteDownloadedFile(material.id);
              ref.invalidate(materialsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Removed offline copy.')),
                );
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Remove download'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ] else
          ElevatedButton.icon(
            onPressed: () => downloadMaterialWithFeedback(context, ref, material),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download for offline'),
          ),
      ],
    );
  }
}
