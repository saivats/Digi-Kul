import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/lecture/lecture_dto.dart';

class LiveLectureBanner extends StatefulWidget {
  const LiveLectureBanner({super.key, required this.lecture});

  final LectureDto lecture;

  @override
  State<LiveLectureBanner> createState() => _LiveLectureBannerState();
}

class _LiveLectureBannerState extends State<LiveLectureBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/session/${widget.lecture.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withValues(alpha: _pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white
                              .withValues(alpha: _pulseAnimation.value * 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE NOW',
                        style: AppTextStyles.labelSmall(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lecture.title,
                        style: AppTextStyles.titleMedium(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.lecture.teacherName,
                        style: AppTextStyles.bodySmall(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Join',
                    style: AppTextStyles.button(color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
