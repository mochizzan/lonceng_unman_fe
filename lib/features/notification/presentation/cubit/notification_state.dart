import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.reminderIntervalMinutes = 5,
    this.errorMessage,
  });

  final NotificationStatus status;
  final List<ScheduledNotificationEntity> notifications;
  final int reminderIntervalMinutes;
  final String? errorMessage;

  NotificationState copyWith({
    NotificationStatus? status,
    List<ScheduledNotificationEntity>? notifications,
    int? reminderIntervalMinutes,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          notifications == other.notifications &&
          reminderIntervalMinutes == other.reminderIntervalMinutes &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(status, notifications, reminderIntervalMinutes, errorMessage);
}
