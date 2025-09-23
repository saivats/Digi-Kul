import 'package:flutter/material.dart';

import 'package:digikul_student_app/src/core/theme/app_colors.dart';
import 'package:digikul_student_app/src/core/theme/app_text_styles.dart';

class LiveSessionScreen extends StatelessWidget {
  
  const LiveSessionScreen({
    super.key,
    required this.sessionId,
  });
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Session'),
        backgroundColor: AppColors.live,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.live_tv,
              size: 64,
              color: AppColors.live,
            ),
            const SizedBox(height: 16),
            const Text(
              'Live Session',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Session ID: $sessionId',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Live session functionality coming soon!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
