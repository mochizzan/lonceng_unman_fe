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

  /// Delete all delivered notification records.
  Future<void> deleteAll() async {
    await _box.clear();
  }
}
