import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digikul_student_app/utils/app_colors.dart';
import 'package:digikul_student_app/utils/app_text_styles.dart';

class LectureDetailsScreen extends ConsumerStatefulWidget {
  
  const LectureDetailsScreen({
    super.key,
    required this.lectureId,
  });
  final String lectureId;

  @override
  ConsumerState<LectureDetailsScreen> createState() => _LectureDetailsScreenState();
}

class _LectureDetailsScreenState extends ConsumerState<LectureDetailsScreen> {
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
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Lecture Details Screen',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'Lecture ID: ${widget.lectureId}',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen will show detailed information about the lecture and materials.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
