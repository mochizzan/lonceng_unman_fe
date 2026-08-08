import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.reminderIntervalMinutes = NotificationConfig.defaultReminderMinutes,
    this.errorMessage,
    this.notificationPermissionDenied = false,
  });

  final NotificationStatus status;
  final List<ScheduledNotificationEntity> notifications;
  final int reminderIntervalMinutes;
  final String? errorMessage;
  final bool notificationPermissionDenied;

  NotificationState copyWith({
    NotificationStatus? status,
    List<ScheduledNotificationEntity>? notifications,
    int? reminderIntervalMinutes,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? notificationPermissionDenied,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      notificationPermissionDenied:
          notificationPermissionDenied ?? this.notificationPermissionDenied,
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
          errorMessage == other.errorMessage &&
          notificationPermissionDenied == other.notificationPermissionDenied;

  @override
  int get hashCode => Object.hash(
    status,
    notifications,
    reminderIntervalMinutes,
    errorMessage,
    notificationPermissionDenied,
  );
}
