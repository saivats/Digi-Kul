import 'package:isar/isar.dart';

part 'cached_attendance.g.dart';

@collection
class CachedAttendance {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String lectureId;
  late String lectureTitle;
  late String status;
  late DateTime lectureDate;
  DateTime? cachedAt;

  @ignore
  bool get isPresent => status == 'present' || status == 'late';
}
