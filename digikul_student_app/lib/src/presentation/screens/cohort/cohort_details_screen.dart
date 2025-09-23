import 'package:flutter/material.dart';

import 'package:digikul_student_app/src/core/theme/app_colors.dart';
import 'package:digikul_student_app/src/core/theme/app_text_styles.dart';

class CohortDetailsScreen extends StatelessWidget {
  
  const CohortDetailsScreen({
    super.key,
    required this.cohortId,
  });
  final String cohortId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cohort Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cohort Details',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cohort ID: $cohortId',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Detailed cohort view coming soon!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
