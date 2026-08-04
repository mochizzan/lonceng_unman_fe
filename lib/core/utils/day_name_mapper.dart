/// Maps Indonesian day names to Dart weekday integers and computes next occurrence.
///
/// Used by the notification scheduler to convert "Senin" → DateTime for
/// scheduling weekly class reminders.
class DayNameMapper {
  DayNameMapper._();

  static const Map<String, int> _dayToWeekday = {
    'Senin': DateTime.monday,
    'Selasa': DateTime.tuesday,
    'Rabu': DateTime.wednesday,
    'Kamis': DateTime.thursday,
    'Jumat': DateTime.friday,
    'Sabtu': DateTime.saturday,
    'Minggu': DateTime.sunday,
  };

  /// Convert Indonesian day name to Dart weekday integer (1=Monday..7=Sunday).
  ///
  /// Throws [ArgumentError] if [dayName] is not a recognized Indonesian day.
  static int weekdayFromName(String dayName) {
    final weekday = _dayToWeekday[dayName];
    if (weekday == null) {
      throw ArgumentError('Unknown day name: $dayName');
    }
    return weekday;
  }

  /// Get the next occurrence of [dayName] from [now].
  ///
  /// If today IS that day, returns today (same date, midnight).
  /// Returns a [DateTime] with year/month/day set to the next occurrence,
  /// time portion is midnight (00:00:00). Caller combines with class time.
  static DateTime nextOccurrence(String dayName, {DateTime? now}) {
    final nowDate = now ?? DateTime.now();
    final targetWeekday = weekdayFromName(dayName);
    final currentWeekday = nowDate.weekday;

    // Days until target: 0 if today, 1-6 if later this week, 0 if today
    final daysUntil = (targetWeekday - currentWeekday) % 7;

    return DateTime(nowDate.year, nowDate.month, nowDate.day + daysUntil);
  }

  /// Get all available day names in Indonesian.
  static List<String> get availableDays => _dayToWeekday.keys.toList();
}
