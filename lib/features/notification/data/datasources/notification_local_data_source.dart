// lib/features/notification/data/datasources/notification_local_data_source.dart
import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';

/// Raw Hive operations for scheduled notifications.
///
/// Does not know about scheduling logic — only CRUD and settings persistence.
class NotificationLocalDataSource {
  NotificationLocalDataSource({
    required this.notificationsBox,
    required this.settingsBox,
  });

  final Box<ScheduledNotificationModel> notificationsBox;
  final Box<int> settingsBox;

  static const _reminderIntervalKey = NotificationConfig.reminderIntervalKey;
  static const int _defaultReminderInterval =
      NotificationConfig.defaultReminderMinutes;

  /// Get all scheduled notifications.
  List<ScheduledNotificationModel> getAll() {
    return notificationsBox.values.toList();
  }

  /// Get a single notification by ID.
  ScheduledNotificationModel? getById(int id) {
    return notificationsBox.get(id);
  }

  /// Insert or update a notification.
  Future<void> save(ScheduledNotificationModel notification) async {
    await notificationsBox.put(notification.id, notification);
  }

  /// Insert or update multiple notifications.
  Future<void> saveAll(List<ScheduledNotificationModel> notifications) async {
    final map = <int, ScheduledNotificationModel>{
      for (final n in notifications) n.id: n,
    };
    await notificationsBox.putAll(map);
  }

  /// Delete a notification by ID.
  Future<void> delete(int id) async {
    await notificationsBox.delete(id);
  }

  /// Delete all notifications.
  Future<void> deleteAll() async {
    await notificationsBox.clear();
  }

  /// Get the reminder interval in minutes.
  int getReminderInterval() {
    return settingsBox.get(_reminderIntervalKey) ?? _defaultReminderInterval;
  }

  /// Set the reminder interval in minutes.
  Future<void> setReminderInterval(int minutes) async {
    await settingsBox.put(_reminderIntervalKey, minutes);
  }
}
