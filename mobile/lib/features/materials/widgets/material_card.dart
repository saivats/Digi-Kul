import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/material/material_dto.dart';
import '../../../repositories/material_repository.dart';

import 'material_type_icon.dart';

class MaterialCard extends ConsumerWidget {
  const MaterialCard({super.key, required this.material});

  final MaterialDto material;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadProgress = ref.watch(downloadProgressProvider);
    final isDownloading = downloadProgress.containsKey(material.id);
    final progress = downloadProgress[material.id] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MaterialTypeIcon(fileType: material.fileType, size: 36),
                const Spacer(),
                if (material.isDownloaded)
                  const Icon(
                    Icons.offline_pin_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              material.title,
              style: AppTextStyles.titleMedium(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${material.fileSizeFormatted} · ${material.uploadedBy}',
              style: AppTextStyles.caption(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (isDownloading)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTextStyles.labelSmall(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              )
            else if (material.isDownloaded)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: AppTextStyles.labelMedium(),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(downloadProgressProvider.notifier)
                        .startDownload(material);
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: const BorderSide(color: AppColors.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: AppTextStyles.labelMedium(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
