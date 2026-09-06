/// Tracks a notification that was actually delivered (shown) to the user.
///
/// For [NotificationSource.classReminder]: created optimistically at schedule
/// time with [deliveredAt] = trigger time (future), filtered by `<= now` in UI.
/// For [NotificationSource.fcm]: created at receive time with [deliveredAt] = now.
enum NotificationSource { classReminder, fcm }

class NotificationDeliveredEntity {
  const NotificationDeliveredEntity({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.classTime,
    required this.deliveredAt,
    required this.room,
    this.lecturer,
    this.isRead = false,
    this.source = NotificationSource.classReminder,
    this.scheduledId,
    this.title,
    this.body,
  });

  /// Per-occurrence delivered ID (hash of scheduledId + trigger millis for
  /// classReminder, hash of fcm messageId + now for FCM). Not equal to
  /// ScheduledNotificationEntity.id.
  final int id;

  /// Course name. For FCM: title ?? body ?? "Notifikasi".
  final String courseName;

  /// Day name in Indonesian (e.g., "Senin"). For FCM: "".
  final String dayOfWeek;

  /// The class start time. For FCM: now.
  final DateTime classTime;

  /// When the notification was delivered/shown (or optimistically scheduled).
  final DateTime deliveredAt;

  /// Room/venue. For FCM: "".
  final String room;

  /// Lecturer name (nullable).
  final String? lecturer;

  /// Whether the user has read this item.
  final bool isRead;

  /// Source of the notification.
  final NotificationSource source;

  /// Link to ScheduledNotificationEntity.id for classReminder, null for FCM.
  final int? scheduledId;

  /// FCM title (null for classReminder).
  final String? title;

  /// FCM body (null for classReminder).
  final String? body;

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
          lecturer == other.lecturer &&
          isRead == other.isRead &&
          source == other.source &&
          scheduledId == other.scheduledId &&
          title == other.title &&
          body == other.body;

  @override
  int get hashCode => Object.hash(
    id,
    courseName,
    dayOfWeek,
    classTime,
    deliveredAt,
    room,
    lecturer,
    isRead,
    source,
    scheduledId,
    title,
    body,
  );
}
