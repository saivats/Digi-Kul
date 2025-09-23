import 'package:flutter/material.dart';
import '../models/cohort.dart';
import '../models/lecture.dart';
import '../services/api_service.dart';
import 'cohort_details_screen.dart'; // We will navigate here
import 'lecture_details_screen.dart'; // We will navigate here

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                trailing: const Icon(Icons.chevron_right),
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