import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';

/// Abstract interface for delivered notification persistence.
abstract class NotificationDeliveredRepository {
  /// Get all delivered notifications, newest first.
  Future<List<NotificationDeliveredEntity>> getAll();

  /// Save a delivered notification record.
  Future<void> save(NotificationDeliveredEntity entity);

  /// Delete a single delivered record.
  Future<void> delete(int id);

  /// Delete all delivered notification records.
  Future<void> deleteAll();

  /// Mark one as read.
  Future<void> markAsRead(int id);

  /// Mark all as read.
  Future<void> markAllRead();

  /// Count unread visible (deliveredAt <= now).
  int getUnreadCount();

  /// Check existence.
  bool containsKey(int id);
}
