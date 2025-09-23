import 'package:flutter/material.dart';
import 'package:digikul_student_app/models/cohort.dart';
import 'package:digikul_student_app/models/lecture.dart';
import 'package:digikul_student_app/services/api_service.dart';
import 'package:digikul_student_app/screens/cohort_details_screen.dart'; // We will navigate here
import 'package:digikul_student_app/screens/lecture_details_screen.dart'; // We will navigate here
import 'package:digikul_student_app/screens/live_session_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late Future<List<Lecture>> _enrolledLecturesFuture;
  late Future<List<Cohort>> _cohortsFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching data when the screen loads
    _enrolledLecturesFuture = ApiService.getEnrolledLectures();
    _cohortsFuture = ApiService.getStudentCohorts();
  }

  void _refreshData() {
    setState(() {
      _enrolledLecturesFuture = ApiService.getEnrolledLectures();
      _cohortsFuture = ApiService.getStudentCohorts();
    });
  }

  Future<void> _showJoinLiveClassDialog() async {
    try {
      // Get all enrolled lectures
      final enrolledLectures = await ApiService.getEnrolledLectures();
      
      // Filter for lectures with active sessions
      final liveLectures = <Lecture>[];
      for (final lecture in enrolledLectures) {
        try {
          final sessionId = await ApiService.getActiveSessionId(lecture.id);
          if (sessionId != null) {
            liveLectures.add(lecture);
          }
        } catch (e) {
          // Session not active, skip this lecture
        }
      }

      if (!context.mounted) return;

      if (liveLectures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('No live classes available right now'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Join Live Class'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a live class to join:'),
                const SizedBox(height: 16),
                ...liveLectures.map((lecture) => ListTile(
                  leading: const Icon(Icons.live_tv, color: Colors.red),
                  title: Text(lecture.title),
                  subtitle: Text('By: ${lecture.teacherName}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final sessionId = await ApiService.getActiveSessionId(lecture.id);
                      if (sessionId != null && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LiveSessionScreen(
                              sessionId: sessionId,
                              lectureId: lecture.id,
                              lectureTitle: lecture.title,
                              teacherName: lecture.teacherName,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('Failed to join live class: ${e}'),
                          ),
                        );
                      }
                    }
                  },
                ),),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to load live classes: ${e}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveClassSection(),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'My Cohorts'),
            _buildCohortsList(),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Enrolled Lectures'),
            _buildEnrolledLecturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLiveClassSection() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.live_tv,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Join Live Class',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join active live sessions from your enrolled courses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showJoinLiveClassDialog,
              icon: const Icon(Icons.videocam),
              label: const Text('Join Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortsList() {
    return FutureBuilder<List<Cohort>>(
      future: _cohortsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('You have not joined any cohorts yet.'));
        }
        final cohorts = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cohorts.length,
          itemBuilder: (context, index) {
            final cohort = cohorts[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.group_work, color: Colors.indigo),
                title: Text(cohort.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(cohort.subject),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // This implements the navigation
                      builder: (context) => CohortDetailsScreen(cohort: cohort), // Pass cohort object here
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnrolledLecturesList() {
    return FutureBuilder<List<Lecture>>(
      future: _enrolledLecturesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('You have not enrolled in any lectures yet.'));
        }
        final lectures = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lectures.length,
          itemBuilder: (context, index) {
            final lecture = lectures[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: Colors.indigo),
                title: Text(lecture.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lecture.teacherName),
                trailing: lecture.sessionActive
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // This implements the navigation
                      builder: (context) => LectureDetailsScreen(lecture: lecture),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}