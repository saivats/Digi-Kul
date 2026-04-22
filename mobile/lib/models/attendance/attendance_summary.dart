import 'dart:math';

import 'attendance_dto.dart';

class AttendanceSummary {
  AttendanceSummary({required List<AttendanceDto> records})
      : totalClasses = records.length,
        presentClasses = records.where((r) => r.isPresent).length;

  final int totalClasses;
  final int presentClasses;

  static const double requiredPercentage = 75.0;

  double get percentage =>
      totalClasses == 0 ? 100.0 : (presentClasses / totalClasses) * 100;

  bool get isBelowThreshold => percentage < requiredPercentage;

  int get classesNeededFor75 {
    if (!isBelowThreshold) return 0;
    final needed =
        ((requiredPercentage * totalClasses / 100) - presentClasses).ceil();
    return max(0, needed);
  }

  int get absentClasses => totalClasses - presentClasses;
}
