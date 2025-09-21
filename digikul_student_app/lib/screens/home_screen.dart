import 'package:flutter/material.dart';
import '../models/lecture.dart';
import '../services/api_service.dart';
import 'lecture_details_screen.dart';
import 'live_session_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  void _showJoinCohortDialog() {
    final TextEditingController codeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Join Cohort'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the cohort code provided by your teacher:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Cohort Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group_work),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (codeController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.orange,
                          content: Text('Please enter a cohort code'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    try {
                      await ApiService.joinCohortByCode(codeController.text.trim());
                      if (!context.mounted) return;
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('Successfully joined cohort!'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Failed to join cohort: ${e.toString()}'),
                        ),
                      );
                    } finally {
                      if (context.mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJoinLiveClassDialog() async {
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
                            content: Text('Failed to join live class: ${e.toString()}'),
                          ),
                        );
                      }
                    }
                  },
                )),
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
            content: Text('Failed to load live classes: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLectures,
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
            padding: const EdgeInsets.all(8),
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.school_outlined, color: Colors.indigo, size: 40),
                  title: Text(lecture.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("By: ${lecture.teacherName}"),
                  trailing: lecture.sessionActive
                      ? Chip(
                          label: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LectureDetailsScreen(lecture: lecture),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _showJoinLiveClassDialog,
            icon: const Icon(Icons.live_tv),
            label: const Text('Join Live Class'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            heroTag: "live_class",
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _showJoinCohortDialog,
            icon: const Icon(Icons.group_add),
            label: const Text('Join Cohort'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            heroTag: "join_cohort",
          ),
        ],
      ),
    );
  }
}