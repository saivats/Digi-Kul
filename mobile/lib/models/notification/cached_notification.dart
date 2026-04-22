import 'package:isar/isar.dart';

part 'cached_notification.g.dart';

@collection
class CachedNotification {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String title;
  late String message;
  late String type;
  bool isRead = false;
  late DateTime createdAt;
  DateTime? cachedAt;
}
