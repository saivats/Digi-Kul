import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/api_service.dart';
// import 'quiz_taking_screen.dart'; // This will be created next

class QuizListScreen extends StatefulWidget {
  final String cohortId;
  final String cohortName;

  const QuizListScreen({
    super.key,
    required this.cohortId,
    required this.cohortName,
  });

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  late Future<List<Quiz>> _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = ApiService.getCohortQuizzes(widget.cohortId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quizzes for ${widget.cohortName}'),
      ),
      body: FutureBuilder<List<Quiz>>(
        future: _quizzesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No quizzes available for this cohort yet.'));
          }

          final quizzes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.quiz_outlined, color: Colors.indigo),
                  title: Text(quiz.question, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Created on: ${quiz.createdAt.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to QuizTakingScreen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Starting quiz... (Not Implemented)')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}