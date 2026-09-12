import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/common/api_response.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/pending_sync_provider.dart';
import '../../../repositories/quiz_repository.dart';
import '../../../widgets/digikul_app_bar.dart';
import '../../../widgets/error_widget.dart';

/// GET /api/students/me — replaces the old "Profile" placeholder tab.
final _profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ref.watch(apiClientProvider).getProfile();
  return ApiResponse.fromResponse(response).parseObject();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_profileProvider);
    final pending = ref.watch(pendingSyncCountProvider).maybeWhen(data: (n) => n, orElse: () => 0);
    final cachedName = PreferencesService.studentName ?? 'Student';
    final cachedEmail = PreferencesService.studentEmail ?? '';

    return Scaffold(
      appBar: const DigikulAppBar(title: 'Profile'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_profileProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            profileAsync.when(
              loading: () => _ProfileCard(name: cachedName, email: cachedEmail),
              error: (e, _) => Column(
                children: [
                  _ProfileCard(name: cachedName, email: cachedEmail, offline: true),
                  const SizedBox(height: 8),
                  AppErrorWidget(
                    message: 'Showing saved details. $e',
                    onRetry: () => ref.invalidate(_profileProvider),
                  ),
                ],
              ),
              data: (p) => _ProfileCard(
                name: (p['name'] as String?) ?? cachedName,
                email: (p['email'] as String?) ?? cachedEmail,
                studentId: p['student_id'] as String?,
                rollNumber: p['roll_number'] as String?,
                className: p['class'] as String?,
                section: p['section'] as String?,
              ),
            ),
            const SizedBox(height: 16),
            _Tile(
              icon: Icons.sync_rounded,
              title: pending > 0 ? 'Sync $pending pending quiz answer${pending == 1 ? '' : 's'}' : 'Everything is synced',
              subtitle: 'Queued answers are sent when you have a connection.',
              onTap: pending == 0
                  ? null
                  : () async {
                      await ref.read(quizRepositoryProvider).syncPendingSubmissions();
                      ref.invalidate(pendingSyncCountProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sync attempted — check the badge.')),
                        );
                      }
                    },
            ),
            _Tile(
              icon: Icons.dns_rounded,
              title: 'Server',
              subtitle: '${ApiConstants.baseUrl} (${ApiConstants.environment})',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text('Downloaded materials stay on this phone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    this.studentId,
    this.rollNumber,
    this.className,
    this.section,
    this.offline = false,
  });

  final String name;
  final String email;
  final String? studentId;
  final String? rollNumber;
  final String? className;
  final String? section;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase();
    final details = [
      if (studentId != null && studentId!.isNotEmpty) 'ID $studentId',
      if (rollNumber != null && rollNumber!.isNotEmpty) 'Roll $rollNumber',
      if (className != null && className!.isNotEmpty) 'Class $className${section != null && section!.isNotEmpty ? '-$section' : ''}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text(initials.isEmpty ? '?' : initials,
                style: AppTextStyles.headlineMedium(color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.titleLarge()),
                const SizedBox(height: 2),
                Text(email, style: AppTextStyles.bodySmall(color: AppColors.textSecondary)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details, style: AppTextStyles.bodySmall(color: AppColors.textSecondary)),
                ],
                if (offline) ...[
                  const SizedBox(height: 4),
                  Text('Saved copy', style: AppTextStyles.labelSmall(color: AppColors.offline)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: AppTextStyles.titleMedium()),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall(color: AppColors.textSecondary)),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
