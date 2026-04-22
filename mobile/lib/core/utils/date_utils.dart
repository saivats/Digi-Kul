import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _timeFormat = DateFormat.jm();
  static final _dateFormat = DateFormat.yMMMd();
  static final _dateTimeFormat = DateFormat.yMMMd().add_jm();
  static final _dayFormat = DateFormat.EEEE();
  static final _shortDateFormat = DateFormat('dd MMM');

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime);

  static String formatDay(DateTime dateTime) => _dayFormat.format(dateTime);

  static String formatShortDate(DateTime dateTime) =>
      _shortDateFormat.format(dateTime);

  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShortDate(dateTime);
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static bool isUpcoming(DateTime dateTime) =>
      dateTime.isAfter(DateTime.now());

  static bool isLive(DateTime scheduledTime, int durationMinutes) {
    final now = DateTime.now();
    final endTime = scheduledTime.add(Duration(minutes: durationMinutes));
    return now.isAfter(scheduledTime) && now.isBefore(endTime);
  }
}
