import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/lecture/cached_lecture.dart';
import '../../models/material/cached_material.dart';
import '../../models/quiz/pending_quiz_submission.dart';
import '../../models/attendance/cached_attendance.dart';
import '../../models/notification/cached_notification.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        CachedLectureSchema,
        CachedMaterialSchema,
        PendingQuizSubmissionSchema,
        CachedAttendanceSchema,
        CachedNotificationSchema,
      ],
      directory: dir.path,
    );
    return _isar!;
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
