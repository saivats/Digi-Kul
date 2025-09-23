import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            'Account',
            [
              _buildSettingsTile(
                Icons.person_outline,
                'Profile',
                'Manage your profile information',
                () => context.push('/profile'),
              ),
              _buildSettingsTile(
                Icons.notifications,
                'Notifications',
                'Configure notification preferences',
                () {
                  // TODO: Implement notifications settings
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            'App Settings',
            [
              _buildSettingsTile(
                Icons.download_outlined,
                'Download Quality',
                'Manage offline content quality',
                () {
                  // TODO: Implement download settings
                },
              ),
              _buildSettingsTile(
                Icons.data_usage_outlined,
                'Data Usage',
                'Control data consumption',
                () {
                  // TODO: Implement data settings
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            'Support',
            [
              _buildSettingsTile(
                Icons.help_outline,
                'Help & FAQ',
                'Get help and find answers',
                () {
                  // TODO: Implement help screen
                },
              ),
              _buildSettingsTile(
                Icons.feedback_outlined,
                'Send Feedback',
                'Share your thoughts with us',
                () {
                  // TODO: Implement feedback
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            'About',
            [
              _buildSettingsTile(
                Icons.info_outline,
                'About Digi-Kul',
                'Version 1.0.0',
                () {
                  // TODO: Implement about screen
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Logout button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (shouldLogout == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading5.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
