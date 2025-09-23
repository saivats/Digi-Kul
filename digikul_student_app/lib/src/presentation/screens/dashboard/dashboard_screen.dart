import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/lecture_provider.dart';
import '../../widgets/common/loading_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${currentUser?.userName ?? 'Student'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                currentUser?.userName.substring(0, 1).toUpperCase() ?? 'U',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => context.go(AppConstants.profileRoute),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => context.go(AppConstants.settingsRoute),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout_outlined),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _handleLogout(),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeTab(),
          _ExploreTab(),
          _DownloadsTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            activeIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledLectures = ref.watch(enrolledLecturesProvider);
    final liveLectures = ref.watch(liveLecturesProvider);
    final upcomingLectures = ref.watch(upcomingLecturesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(enrolledLecturesProvider.notifier).refresh();
        ref.invalidate(liveLecturesProvider);
        ref.invalidate(upcomingLecturesProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(context),
            
            const SizedBox(height: 24),
            
            // Live Lectures
            _buildSection(
              context,
              title: 'Live Now',
              icon: Icons.live_tv,
              color: AppColors.live,
              child: liveLectures.when(
                data: (lectures) => lectures.isEmpty
                    ? const _EmptyState(message: 'No live lectures at the moment')
                    : _LecturesList(lectures: lectures, isLive: true),
                loading: () => const _LoadingWidget(),
                error: (error, _) => _ErrorWidget(error: error.toString()),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Upcoming Lectures
            _buildSection(
              context,
              title: 'Upcoming',
              icon: Icons.schedule,
              color: AppColors.upcoming,
              child: upcomingLectures.when(
                data: (lectures) => lectures.isEmpty
                    ? const _EmptyState(message: 'No upcoming lectures')
                    : _LecturesList(lectures: lectures.take(3).toList()),
                loading: () => const _LoadingWidget(),
                error: (error, _) => _ErrorWidget(error: error.toString()),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // All Enrolled Lectures
            _buildSection(
              context,
              title: 'My Lectures',
              icon: Icons.school,
              color: AppColors.primary,
              child: enrolledLectures.when(
                data: (lectures) => lectures.isEmpty
                    ? const _EmptyState(message: 'No enrolled lectures yet')
                    : _LecturesList(lectures: lectures.take(5).toList()),
                loading: () => const _LoadingWidget(),
                error: (error, _) => _ErrorWidget(error: error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              icon: Icons.school,
              label: 'Enrolled',
              value: '12',
              color: AppColors.primary,
            ),
            _buildStatItem(
              context,
              icon: Icons.live_tv,
              label: 'Live',
              value: '2',
              color: AppColors.live,
            ),
            _buildStatItem(
              context,
              icon: Icons.schedule,
              label: 'Upcoming',
              value: '5',
              color: AppColors.upcoming,
            ),
            _buildStatItem(
              context,
              icon: Icons.download,
              label: 'Downloaded',
              value: '8',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full list
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _LecturesList extends StatelessWidget {
  final List lectures;
  final bool isLive;

  const _LecturesList({
    required this.lectures,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: lectures.map((lecture) => _LectureCard(
        lecture: lecture,
        isLive: isLive,
      )).toList(),
    );
  }
}

class _LectureCard extends StatelessWidget {
  final dynamic lecture;
  final bool isLive;

  const _LectureCard({
    required this.lecture,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLive ? AppColors.live : AppColors.primary,
          child: Icon(
            isLive ? Icons.live_tv : Icons.school,
            color: AppColors.textOnPrimary,
            size: 20,
          ),
        ),
        title: Text(
          'Sample Lecture Title',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. Sample Teacher',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (isLive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LIVE',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: () {
          // TODO: Navigate to lecture details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lecture details coming soon')),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading data',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Placeholder tabs
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Explore Tab - Coming Soon'),
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Downloads Tab - Coming Soon'),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Tab - Coming Soon'),
    );
  }
}
