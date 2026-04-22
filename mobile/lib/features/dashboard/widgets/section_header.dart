import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.trailing,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.titleLarge()),
          if (trailing != null)
            trailing!
          else if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: AppTextStyles.labelMedium(color: AppColors.primaryLight),
              ),
            ),
        ],
      ),
    );
  }
}
