import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:digikul_student_app/providers/auth_provider.dart';
import 'package:digikul_student_app/providers/lecture_provider.dart';
import 'package:digikul_student_app/providers/cohort_provider.dart';
import 'package:digikul_student_app/providers/poll_provider.dart';
import 'package:digikul_student_app/models/lecture.dart';
import 'package:digikul_student_app/models/cohort.dart';
import 'package:digikul_student_app/models/poll.dart';
import 'package:digikul_student_app/utils/app_colors.dart';
import 'package:digikul_student_app/utils/app_text_styles.dart';
import 'package:digikul_student_app/widgets/custom_button.dart';
import 'package:digikul_student_app/widgets/loading_overlay.dart';
import 'package:digikul_student_app/widgets/lecture_card.dart';
import 'package:digikul_student_app/widgets/cohort_card.dart';
import 'package:digikul_student_app/widgets/poll_card.dart';
import 'package:digikul_student_app/widgets/network_status_indicator.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _cohortCodeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cohortCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      ref.read(lecturesProvider.notifier).loadEnrolledLectures(),
      ref.read(cohortsProvider.notifier).loadStudentCohorts(),
      ref.read(pollsProvider.notifier).loadStudentPolls(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  void _showJoinCohortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Cohort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the cohort code provided by your teacher:'),
            const SizedBox(height: 16),
            TextField(
              controller: _cohortCodeController,
              decoration: const InputDecoration(
                labelText: 'Cohort Code',
                hintText: 'e.g., ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
                CustomTextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cohortCodeController.clear();
            },
            text: 'Cancel',
          ),
          ElevatedButton(
            onPressed: () async {
              final code = _cohortCodeController.text.trim();
              if (code.isNotEmpty) {
                try {
                  await ref.read(cohortsProvider.notifier).joinCohortByCode(code);
                  if (mounted) {
                    Navigator.of(context).pop();
                    _cohortCodeController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully joined cohort!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to join cohort: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final lecturesState = ref.watch(lecturesProvider);
    final cohortsState = ref.watch(cohortsProvider);
    final pollsState = ref.watch(pollsProvider);
    final upcomingLectures = ref.watch(upcomingLecturesProvider);
    final liveLectures = ref.watch(liveLecturesProvider);
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.primaryGradient,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Text(
                                  user?.name.isNotEmpty ?? false 
                                      ? user!.name[0].toUpperCase()
                                      : 'S',
                                  style: AppTextStyles.heading4.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      user?.name ?? 'Student',
                                      style: AppTextStyles.heading3.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const NetworkStatusIndicator(),
                              IconButton(
                                onPressed: () => context.push('/settings'),
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Quick Stats
                          Row(
                            children: [
                              _buildStatCard(
                                'Enrolled Lectures',
                                '${lecturesState.enrolledLectures.length}',
                                Icons.school,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                'Joined Cohorts',
                                '${cohortsState.studentCohorts.length}',
                                Icons.group,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                'Active Polls',
                                '${pollsState.studentPolls.length}',
                                Icons.poll,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Lectures'),
                  Tab(text: 'Cohorts'),
                  Tab(text: 'Polls'),
                ],
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(upcomingLectures, liveLectures),
              _buildLecturesTab(lecturesState.enrolledLectures),
              _buildCohortsTab(cohortsState.studentCohorts),
              _buildPollsTab(pollsState.studentPolls),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: _showJoinCohortDialog,
              icon: const Icon(Icons.add),
              label: const Text('Join Cohort'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.heading4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(List<Lecture> upcomingLectures, List<Lecture> liveLectures) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Lectures Section
          if (liveLectures.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Now',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.live,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...liveLectures.map((lecture) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LectureCard(
                lecture: lecture,
                onTap: () => context.push('/lecture/${lecture.id}'),
                showLiveIndicator: true,
              ),
            ),),
            const SizedBox(height: 24),
          ],
          
          // Upcoming Lectures Section
          const Text(
            'Upcoming Lectures',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: 12),
          if (upcomingLectures.isEmpty)
            _buildEmptyState(
              'No upcoming lectures',
              "You don't have any lectures scheduled. Browse available lectures to enroll.",
              Icons.schedule,
              () => context.push('/explore'),
              'Browse Lectures',
            )
          else
            ...upcomingLectures.take(3).map((lecture) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LectureCard(
                lecture: lecture,
                onTap: () => context.push('/lecture/${lecture.id}'),
              ),
            ),),
          
          if (upcomingLectures.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                child: const Text('View All Lectures'),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Explore Lectures',
                  'Find new courses',
                  Icons.explore,
                  AppColors.primary,
                  () => context.push('/explore'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Downloads',
                  'Offline materials',
                  Icons.download,
                  AppColors.secondary,
                  () => context.push('/downloads'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturesTab(List<Lecture> lectures) {
    if (lectures.isEmpty) {
      return _buildEmptyState(
        'No lectures enrolled',
        'Start your learning journey by enrolling in lectures.',
        Icons.school_outlined,
        () => context.push('/explore'),
        'Browse Lectures',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lectures.length,
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LectureCard(
            lecture: lecture,
            onTap: () => context.push('/lecture/${lecture.id}'),
            showLiveIndicator: lecture.isLive,
          ),
        );
      },
    );
  }

  Widget _buildCohortsTab(List<Cohort> cohorts) {
    if (cohorts.isEmpty) {
      return _buildEmptyState(
        'No cohorts joined',
        'Join cohorts to connect with classmates and access group lectures.',
        Icons.group_outlined,
        _showJoinCohortDialog,
        'Join Cohort',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cohorts.length,
      itemBuilder: (context, index) {
        final cohort = cohorts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CohortCard(
            cohort: cohort,
            onTap: () => context.push('/cohort/${cohort.id}'),
          ),
        );
      },
    );
  }

  Widget _buildPollsTab(List<Poll> polls) {
    if (polls.isEmpty) {
      return _buildEmptyState(
        'No active polls',
        'Polls will appear here when your teachers create them.',
        Icons.poll_outlined,
        null,
        null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length,
      itemBuilder: (context, index) {
        final poll = polls[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PollCard(
            poll: poll,
            onVote: (option) async {
              try {
                await ref.read(pollsProvider.notifier).voteOnPoll(poll.id, option);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vote submitted successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit vote: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    String title,
    String message,
    IconData icon,
    VoidCallback? onAction,
    String? actionText,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                onPressed: onAction,
                text: actionText,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
