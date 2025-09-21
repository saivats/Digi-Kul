import 'package:flutter/material.dart';
import '../models/cohort.dart';
import '../models/lecture.dart';
import '../services/api_service.dart';
import 'lecture_details_screen.dart';

// --- Theme Colors ---
const Color primaryColor = Color(0xFF5247eb);
const Color backgroundLight = Color(0xFFf6f6f8);

class CohortDetailsScreen extends StatefulWidget {
  final Cohort cohort;
  
  const CohortDetailsScreen({super.key, required this.cohort});

  @override
  State<CohortDetailsScreen> createState() => _CohortDetailsScreenState();
}

class _CohortDetailsScreenState extends State<CohortDetailsScreen> {
  late Future<List<Lecture>> _lecturesFuture;

  @override
  void initState() {
    super.initState();
    _lecturesFuture = _fetchCohortLectures();
  }

  Future<List<Lecture>> _fetchCohortLectures() async {
    // Use the correct API endpoint for cohort-specific lectures
    return ApiService.getCohortLectures(widget.cohort.id);
  }

  void _refreshLectures() {
    setState(() {
      _lecturesFuture = _fetchCohortLectures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.cohort.name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLectures,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cohort Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cohort.teacherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.cohort.subject,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.cohort.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Lectures Section
            const Text(
              'Lectures in this Cohort',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Lectures List
            FutureBuilder<List<Lecture>>(
              future: _lecturesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No lectures available in this cohort.'));
                }

                final lectures = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lectures.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lecture = lectures[index];
                    return _LectureCard(lecture: lecture);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LectureCard extends StatelessWidget {
  final Lecture lecture;

  const _LectureCard({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LectureDetailsScreen(lecture: lecture),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lecture.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (lecture.sessionActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lecture.teacherName,
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lecture.scheduledTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}