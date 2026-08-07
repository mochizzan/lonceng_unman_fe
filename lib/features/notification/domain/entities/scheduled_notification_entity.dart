import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';

/// A single scheduled local notification for a class reminder.
///
/// Represents one alarm: "remind me 5 minutes before Algoritma on Senin at 08:00".
/// The [id] is deterministic (computed from courseName + day + hour) and serves
/// as both the Hive key and the flutter_local_notifications alarm ID.
class ScheduledNotificationEntity {
  const ScheduledNotificationEntity({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.classTime,
    required this.reminderOffset,
    required this.room,
    this.lecturer,
    required this.isActive,
  });

  /// Unique notification ID — computed from courseName + day + hour.
  /// Formula: `'$courseName|$dayName|$hour'.hashCode & 0x7FFFFFFF`
  final int id;

  /// Course name (e.g., "Algoritma Pemrograman").
  final String courseName;

  /// Day name in Indonesian (e.g., "Senin").
  final String dayOfWeek;

  /// The class start time — only time-of-day matters (hour, minute).
  /// The date portion is recomputed each week from [dayOfWeek].
  final DateTime classTime;

  /// Minutes before [classTime] to fire the notification (e.g., 5, 10, 15, 30, 60).
  final int reminderOffset;

  /// Room/venue (e.g., "R.301 Gedung A").
  final String room;

  /// Lecturer name (nullable — not all classes have assigned lecturers).
  final String? lecturer;

  /// Whether this notification is enabled by the user.
  final bool isActive;

  /// Creates a list of [ScheduledNotificationEntity] from a [JadwalEntity].
  ///
  /// Each [ScheduleItemEntity] in [jadwal] becomes one notification entity.
  /// The [dayOfWeek] is taken from [jadwal.selectedDay].
  /// Defaults: [reminderOffset] = 5 minutes, [isActive] = true.
  static List<ScheduledNotificationEntity> fromJadwalEntity(
    JadwalEntity jadwal, {
    int defaultReminderOffset = NotificationConfig.defaultReminderMinutes,
    bool defaultIsActive = true,
  }) {
    return jadwal.scheduleItems
        .map(
          (item) => ScheduledNotificationEntity(
            id: computeId(
              item.courseName,
              jadwal.selectedDay,
              item.startTime.hour,
            ),
            courseName: item.courseName,
            dayOfWeek: jadwal.selectedDay,
            classTime: item.startTime,
            reminderOffset: defaultReminderOffset,
            room: item.room,
            lecturer: item.lecturer,
            isActive: defaultIsActive,
          ),
        )
        .toList();
  }

  /// Compute deterministic notification ID from course, day, and hour.
  ///
  /// Ensures re-scheduling overwrites the same alarm (no duplicates).
  static int computeId(String courseName, String dayName, int hour) {
    final key = '$courseName|$dayName|$hour';
    return key.hashCode & 0x7FFFFFFF; // Ensure positive (31-bit)
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledNotificationEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseName == other.courseName &&
          dayOfWeek == other.dayOfWeek &&
          classTime == other.classTime &&
          reminderOffset == other.reminderOffset &&
          room == other.room &&
          lecturer == other.lecturer &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
    id,
    courseName,
    dayOfWeek,
    classTime,
    reminderOffset,
    room,
    lecturer,
    isActive,
  );
}
