import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lecture.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LectureCard extends StatelessWidget {
  final Lecture lecture;
  final VoidCallback? onTap;
  final bool showLiveIndicator;

  const LectureCard({
    super.key,
    required this.lecture,
    this.onTap,
    this.showLiveIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lecture.title,
                      style: AppTextStyles.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showLiveIndicator && lecture.isLive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.live,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    _buildStatusChip(),
                ],
              ),
              
              if (lecture.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lecture.description,
                  style: AppTextStyles.cardSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Lecture details
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lecture.displayTeacherName,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(lecture.scheduledAt),
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(lecture.duration),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;

    if (lecture.isLive) {
      backgroundColor = AppColors.live;
      textColor = Colors.white;
      statusText = 'LIVE';
      icon = Icons.circle;
    } else if (lecture.isUpcoming) {
      backgroundColor = AppColors.upcoming.withOpacity(0.1);
      textColor = AppColors.upcoming;
      statusText = 'UPCOMING';
      icon = Icons.schedule;
    } else if (lecture.isOngoing) {
      backgroundColor = AppColors.warning.withOpacity(0.1);
      textColor = AppColors.warning;
      statusText = 'ONGOING';
      icon = Icons.play_circle_outline;
    } else {
      backgroundColor = AppColors.ended.withOpacity(0.1);
      textColor = AppColors.ended;
      statusText = 'ENDED';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: AppTextStyles.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
    } else if (difference.inDays > 0) {
      return DateFormat('EEE, MMM dd • HH:mm').format(dateTime);
    } else if (difference.inDays == 0) {
      return 'Today • ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == -1) {
      return 'Yesterday • ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM dd • HH:mm').format(dateTime);
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }
}
