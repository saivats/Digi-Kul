import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/connectivity_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    if (connectivity.isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Showing cached data.',
              style: AppTextStyles.labelMedium(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
