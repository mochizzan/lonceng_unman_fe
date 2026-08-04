// lib/features/notification/data/datasources/notification_local_data_source.dart
import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';

/// Raw Hive operations for scheduled notifications.
///
/// Does not know about scheduling logic — only CRUD and settings persistence.
class NotificationLocalDataSource {
  NotificationLocalDataSource({
    required Box<ScheduledNotificationModel> notificationsBox,
    required Box<int> settingsBox,
  }) : _notificationsBox = notificationsBox,
       _settingsBox = settingsBox;

  final Box<ScheduledNotificationModel> _notificationsBox;
  final Box<int> _settingsBox;

  static const _reminderIntervalKey = 'reminder_interval_minutes';
  static const int _defaultReminderInterval = 5;

  /// Get all scheduled notifications.
  List<ScheduledNotificationModel> getAll() {
    return _notificationsBox.values.toList();
  }

  /// Get a single notification by ID.
  ScheduledNotificationModel? getById(int id) {
    return _notificationsBox.get(id);
  }

  /// Insert or update a notification.
  Future<void> save(ScheduledNotificationModel notification) async {
    await _notificationsBox.put(notification.id, notification);
  }

  /// Insert or update multiple notifications.
  Future<void> saveAll(List<ScheduledNotificationModel> notifications) async {
    final map = <int, ScheduledNotificationModel>{
      for (final n in notifications) n.id: n,
    };
    await _notificationsBox.putAll(map);
  }

  /// Delete a notification by ID.
  Future<void> delete(int id) async {
    await _notificationsBox.delete(id);
  }

  /// Delete all notifications.
  Future<void> deleteAll() async {
    await _notificationsBox.clear();
  }

  /// Get the reminder interval in minutes.
  int getReminderInterval() {
    return _settingsBox.get(_reminderIntervalKey) ?? _defaultReminderInterval;
  }

  /// Set the reminder interval in minutes.
  Future<void> setReminderInterval(int minutes) async {
    await _settingsBox.put(_reminderIntervalKey, minutes);
  }
}
