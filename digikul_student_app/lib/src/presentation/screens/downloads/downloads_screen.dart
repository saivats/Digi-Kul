import 'package:flutter/material.dart';

import 'package:digikul_student_app/src/core/theme/app_colors.dart';
import 'package:digikul_student_app/src/core/theme/app_text_styles.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Downloaded Content',
              style: AppTextStyles.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'Access your offline content here.\nComing soon!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
