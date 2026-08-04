import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

/// Abstract interface for scheduled notification persistence and settings.
///
/// Implementations handle the actual storage (Hive, SharedPreferences, etc.).
abstract class NotificationRepository {
  /// Get all scheduled notifications.
  Future<List<ScheduledNotificationEntity>> getAll();

  /// Get a single notification by ID.
  Future<ScheduledNotificationEntity?> getById(int id);

  /// Insert or update a notification.
  Future<void> save(ScheduledNotificationEntity notification);

  /// Insert or update multiple notifications.
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications);

  /// Delete a notification by ID.
  Future<void> delete(int id);

  /// Delete all notifications.
  Future<void> deleteAll();

  /// Get the reminder interval in minutes (from settings).
  /// Returns 5 (default) if not yet set.
  int getReminderInterval();

  /// Set the reminder interval in minutes.
  void setReminderInterval(int minutes);
}
