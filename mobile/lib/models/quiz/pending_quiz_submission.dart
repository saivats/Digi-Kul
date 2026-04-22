import 'package:isar/isar.dart';

part 'pending_quiz_submission.g.dart';

@collection
class PendingQuizSubmission {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String attemptId;

  late String quizSetId;
  late String studentId;
  late String answersJson;
  late DateTime startedAt;
  late DateTime attemptedAt;
  bool isSynced = false;
  int syncAttempts = 0;
  String? syncError;
}
