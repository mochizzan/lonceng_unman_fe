import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/notification_delivered_model.dart';

/// Hive-backed data source for delivered notification tracking.
class NotificationDeliveredLocalDataSource {
  NotificationDeliveredLocalDataSource({
    required Box<NotificationDeliveredModel> box,
  }) : _box = box;

  final Box<NotificationDeliveredModel> _box;

  static const _tombstonePrefix = 'del_tomb_';

  Box<int>? get _settingsBox {
    final name = NotificationConfig.notificationSettingsBox;
    if (Hive.isBoxOpen(name)) return Hive.box<int>(name);
    return null;
  }

  bool _isTombstoned(int id) {
    final b = _settingsBox;
    if (b == null) return false;
    return b.containsKey('$_tombstonePrefix$id');
  }

  Future<void> _addTombstone(int id) async {
    final b = _settingsBox;
    if (b == null) {
      debugPrint(
        '[DELIVERED] _addTombstone skip — settingsBox not open id=$id',
      );
      return;
    }
    await b.put('$_tombstonePrefix$id', 1);
    debugPrint('[DELIVERED] tombstone added id=$id');
  }

  /// Public: tombstone arbitrary id (used by cubit for deleteAll window).
  Future<void> addTombstone(int id) => _addTombstone(id);

  bool isTombstoned(int id) => _isTombstoned(id);

  /// Save a delivered notification record (tombstoned ids are ignored — preserves user delete).
  Future<void> save(NotificationDeliveredModel model) async {
    if (_isTombstoned(model.id)) {
      debugPrint('[DELIVERED] save skip tombstoned id=${model.id}');
      return;
    }
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

  /// Delete a single delivered record and tombstone it so reconcile won't recreate.
  Future<void> delete(int id) async {
    await _box.delete(id);
    await _addTombstone(id);
  }

  /// Delete all delivered notification records and tombstone current window ids.
  /// We snapshot existing deliveredIds then tombstone each so future reconcile
  /// for same window does not resurrect them. Window slides, so stale tombstones
  /// are bounded (12 entries per schedule).
  Future<void> deleteAll() async {
    final ids = _box.keys.cast<int>().toList();
    await _box.clear();
    for (final id in ids) {
      await _addTombstone(id);
    }
    // Also tombstone any generated-but-not-yet-saved window? Nothing to do — future
    // saves for those ids will be tombstoned only if user explicitly deleted.
    // For deleteAll we tombstone the full current reconcile window so restart
    // does not refill past weeks. Compute via scheduled boxes when possible
    // via caller (cubit) — fallback here already covers visible rows.
    debugPrint('[DELIVERED] deleteAll tombstoned ${ids.length} ids');
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
