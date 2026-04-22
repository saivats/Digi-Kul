import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MaterialTypeIcon extends StatelessWidget {
  const MaterialTypeIcon({super.key, required this.fileType, this.size = 40});

  final String fileType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final config = _iconConfig;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: size > 32
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(config.icon, size: size * 0.4, color: config.color),
                  Text(
                    config.label,
                    style: AppTextStyles.labelSmall(color: config.color),
                  ),
                ],
              )
            : Icon(config.icon, size: size * 0.5, color: config.color),
      ),
    );
  }

  _IconConfig get _iconConfig {
    return switch (fileType.toLowerCase()) {
      'pdf' => const _IconConfig(Icons.picture_as_pdf_rounded, AppColors.error, 'PDF'),
      'doc' || 'docx' => const _IconConfig(Icons.description_rounded, AppColors.info, 'DOC'),
      'ppt' || 'pptx' => const _IconConfig(Icons.slideshow_rounded, AppColors.warning, 'PPT'),
      'xls' || 'xlsx' => const _IconConfig(Icons.grid_on_rounded, AppColors.success, 'XLS'),
      'mp4' || 'avi' || 'mov' => const _IconConfig(Icons.video_file_rounded, AppColors.primaryLight, 'VID'),
      'mp3' || 'wav' => const _IconConfig(Icons.audio_file_rounded, AppColors.accent, 'AUD'),
      'jpg' || 'jpeg' || 'png' || 'gif' => const _IconConfig(Icons.image_rounded, AppColors.success, 'IMG'),
      'zip' || 'rar' => const _IconConfig(Icons.folder_zip_rounded, AppColors.textSecondary, 'ZIP'),
      _ => _IconConfig(Icons.insert_drive_file_rounded, AppColors.textSecondary, fileType.toUpperCase()),
    };
  }
}

class _IconConfig {
  const _IconConfig(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}
