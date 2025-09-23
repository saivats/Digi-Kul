import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cohort.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CohortCard extends StatelessWidget {
  final Cohort cohort;
  final VoidCallback? onTap;

  const CohortCard({
    super.key,
    required this.cohort,
    this.onTap,
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
              // Header with name and subject
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(cohort.subject).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubjectIcon(cohort.subject),
                      color: _getSubjectColor(cohort.subject),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cohort.name,
                          style: AppTextStyles.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cohort.subject,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _getSubjectColor(cohort.subject),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cohort.code,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              
              if (cohort.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  cohort.displayDescription,
                  style: AppTextStyles.cardSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer with teacher info and join date
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
                      cohort.displayTeacherName,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (cohort.joinedAt != null) ...[
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined ${_formatJoinDate(cohort.joinedAt!)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    // Generate a color based on subject name
    final hash = subject.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.info,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
      const Color(0xFFE91E63), // Pink
    ];
    
    return colors[hash.abs() % colors.length];
  }

  IconData _getSubjectIcon(String subject) {
    final subjectLower = subject.toLowerCase();
    
    if (subjectLower.contains('math') || subjectLower.contains('calculus')) {
      return Icons.calculate_outlined;
    } else if (subjectLower.contains('science') || 
               subjectLower.contains('physics') || 
               subjectLower.contains('chemistry') || 
               subjectLower.contains('biology')) {
      return Icons.science_outlined;
    } else if (subjectLower.contains('computer') || 
               subjectLower.contains('programming') || 
               subjectLower.contains('coding')) {
      return Icons.computer_outlined;
    } else if (subjectLower.contains('english') || 
               subjectLower.contains('literature') || 
               subjectLower.contains('language')) {
      return Icons.translate_outlined;
    } else if (subjectLower.contains('history') || 
               subjectLower.contains('social')) {
      return Icons.history_edu_outlined;
    } else if (subjectLower.contains('art') || 
               subjectLower.contains('design')) {
      return Icons.palette_outlined;
    } else if (subjectLower.contains('music')) {
      return Icons.music_note_outlined;
    } else if (subjectLower.contains('business') || 
               subjectLower.contains('economics')) {
      return Icons.business_outlined;
    } else {
      return Icons.book_outlined;
    }
  }

  String _formatJoinDate(DateTime joinDate) {
    final now = DateTime.now();
    final difference = now.difference(joinDate);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      return DateFormat('MMM yyyy').format(joinDate);
    }
  }
}
