import 'package:flutter/material.dart';

import 'package:digikul_student_app/src/core/theme/app_colors.dart';
import 'package:digikul_student_app/src/core/theme/app_text_styles.dart';

class LectureDetailsScreen extends StatelessWidget {
  
  const LectureDetailsScreen({
    super.key,
    required this.lectureId,
  });
  final String lectureId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Lecture Details',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Lecture ID: $lectureId',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Detailed lecture view coming soon!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
