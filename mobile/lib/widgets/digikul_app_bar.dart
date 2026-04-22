import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class DigikulAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DigikulAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showLogo = false,
    this.bottom,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Digi-Kul',
                  style: AppTextStyles.titleLarge(color: AppColors.primary),
                ),
              ],
            )
          : title != null
              ? Text(title!, style: AppTextStyles.titleLarge())
              : null,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
