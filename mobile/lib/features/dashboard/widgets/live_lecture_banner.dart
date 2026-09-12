import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/lecture/lecture_dto.dart';

/// "LIVE NOW" card. Static (no animation controller) on purpose — this
/// runs on low-end Android; the only motion in the system is the live dot
/// on the web, and here even that is a plain circle.
class LiveLectureBanner extends StatelessWidget {
  const LiveLectureBanner({
    super.key,
    required this.lecture,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
  });

  final LectureDto lecture;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final startedAgo = AppDateUtils.timeAgo(lecture.scheduledTime);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.live,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(
            '/session/${lecture.sessionId ?? lecture.id}',
            extra: lecture.title,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE NOW',
                        style: AppTextStyles.eyebrow(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lecture.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge(color: Colors.white)
                            .copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (lecture.teacherName.isNotEmpty) lecture.teacherName,
                          'started $startedAgo',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(
                          color: const Color(0xFFFFE4E6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Join',
                    style: AppTextStyles.button(color: AppColors.live)
                        .copyWith(fontWeight: FontWeight.w700),
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
