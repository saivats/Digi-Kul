import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CohortDetailsScreen extends ConsumerStatefulWidget {
  final String cohortId;
  
  const CohortDetailsScreen({
    super.key,
    required this.cohortId,
  });

  @override
  ConsumerState<CohortDetailsScreen> createState() => _CohortDetailsScreenState();
}

class _CohortDetailsScreenState extends ConsumerState<CohortDetailsScreen> {
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
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cohort Details Screen',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'Cohort ID: ${widget.cohortId}',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen will show detailed information about the cohort.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
