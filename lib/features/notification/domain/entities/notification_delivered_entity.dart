/// Tracks a notification that was actually delivered (shown) to the user.
///
/// Logged when `onDidReceiveNotificationResponse` fires, meaning the user
/// saw/tapped the notification on their device.
class NotificationDeliveredEntity {
  const NotificationDeliveredEntity({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.classTime,
    required this.deliveredAt,
    required this.room,
    this.lecturer,
  });

  /// Notification ID (matches ScheduledNotificationEntity.id).
  final int id;

  /// Course name.
  final String courseName;

  /// Day name in Indonesian (e.g., "Senin").
  final String dayOfWeek;

  /// The class start time.
  final DateTime classTime;

  /// When the notification was actually delivered/shown.
  final DateTime deliveredAt;

  /// Room/venue.
  final String room;

  /// Lecturer name (nullable).
  final String? lecturer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationDeliveredEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseName == other.courseName &&
          dayOfWeek == other.dayOfWeek &&
          classTime == other.classTime &&
          deliveredAt == other.deliveredAt &&
          room == other.room &&
          lecturer == other.lecturer;

  @override
  int get hashCode => Object.hash(
    id,
    courseName,
    dayOfWeek,
    classTime,
    deliveredAt,
    room,
    lecturer,
  );
}
