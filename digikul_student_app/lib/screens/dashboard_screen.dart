import 'package:flutter/material.dart';
import '../models/lecture.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Lecture>> _lecturesFuture;

  @override
  void initState() {
    super.initState();
    _lecturesFuture = ApiService.getAvailableLectures();
  }

  void _refreshLectures() {
    setState(() {
      _lecturesFuture = ApiService.getAvailableLectures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Lectures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLectures,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Join a Cohort',
            onPressed: () {
              // TODO: Implement the dialog to enter a cohort code
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Lecture>>(
        future: _lecturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No lectures available.'));
          }

          final lectures = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              return LectureCard(lecture: lectures[index]);
            },
          );
        },
      ),
    );
  }
}

class LectureCard extends StatelessWidget {
  final Lecture lecture;

  const LectureCard({required this.lecture, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Lecture Details screen
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lecture.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'By ${lecture.teacherName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(lecture.description),
            ],
          ),
        ),
      ),
    );
  }
}