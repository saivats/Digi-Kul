import 'package:isar/isar.dart';

part 'cached_quiz_set.g.dart';

@collection
class CachedQuizSet {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String title;
  late String description;
  late String cohortId;
  late int questionCount;
  int? timeLimitSeconds;
  bool showCorrectAnswers = true;
  late DateTime availableFrom;
  DateTime? availableUntil;
  late String status;
  DateTime? cachedAt;
}
