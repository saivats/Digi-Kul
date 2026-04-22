import 'package:isar/isar.dart';

part 'cached_lecture.g.dart';

@collection
class CachedLecture {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String title;
  late String description;
  late DateTime scheduledTime;
  late int durationMinutes;
  late String status;
  late String cohortId;
  late String teacherName;
  String? recordingId;
  DateTime? cachedAt;

  @ignore
  bool get isLive => status == 'live';

  @ignore
  bool get isUpcoming =>
      status == 'scheduled' && scheduledTime.isAfter(DateTime.now());

  @ignore
  bool get isPast => status == 'ended';

  @ignore
  Duration get timeUntilStart => scheduledTime.difference(DateTime.now());
}
