import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String? lectureId;
  
  const LiveSessionScreen({
    super.key,
    required this.sessionId,
    this.lectureId,
  });

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Session'),
        backgroundColor: AppColors.live,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.live.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam,
                size: 64,
                color: AppColors.live,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Live Session Screen',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'Session ID: ${widget.sessionId}',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.lectureId != null) ...[
              Text(
                'Lecture ID: ${widget.lectureId}',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'This screen will handle WebRTC video/audio streaming and real-time chat.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
