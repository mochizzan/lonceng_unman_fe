import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/notification_delivered_model.dart';

/// Hive-backed data source for delivered notification tracking.
class NotificationDeliveredLocalDataSource {
  NotificationDeliveredLocalDataSource({
    required Box<NotificationDeliveredModel> box,
  }) : _box = box;

  final Box<NotificationDeliveredModel> _box;

  /// Save a delivered notification record.
  Future<void> save(NotificationDeliveredModel model) async {
    await _box.put(model.id, model);
  }

  /// Check if a delivered record exists for [id].
  bool containsKey(int id) => _box.containsKey(id);

  /// Get all delivered notifications, newest first.
  List<NotificationDeliveredModel> getAll() {
    final items = _box.values.toList();
    items.sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    return items;
  }

  /// Get delivered notifications within a date range.
  List<NotificationDeliveredModel> getByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _box.values.where((m) {
      return m.deliveredAt.isAfter(start) && m.deliveredAt.isBefore(end);
    }).toList();
  }

  /// Get all models filtered by original scheduledId.
  List<NotificationDeliveredModel> getByScheduledId(int scheduledId) {
    return _box.values.where((m) => m.scheduledId == scheduledId).toList();
  }

  /// Mark a single item as read.
  Future<void> markAsRead(int id) async {
    final m = _box.get(id);
    if (m == null) return;
    if (m.isRead) return;
    await _box.put(id, m.copyWith(isRead: true));
  }

  /// Mark all visible items as read (future optimistic excluded).
  Future<void> markAllRead() async {
    final now = DateTime.now();
    for (final m in _box.values) {
      if (!m.isRead && !m.deliveredAt.isAfter(now)) {
        await _box.put(m.id, m.copyWith(isRead: true));
      }
    }
  }

  /// Delete a single delivered record.
  Future<void> delete(int id) async {
    await _box.delete(id);
  }

  /// Delete all delivered notification records.
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// Count unread visible items (deliveredAt <= now).
  int getUnreadCount() {
    final now = DateTime.now();
    return _box.values
        .where((m) => !m.isRead && !m.deliveredAt.isAfter(now))
        .length;
  }

  /// Expose values for reconciliation (per scheduledId grouping).
  Iterable<NotificationDeliveredModel> get values => _box.values;
}
