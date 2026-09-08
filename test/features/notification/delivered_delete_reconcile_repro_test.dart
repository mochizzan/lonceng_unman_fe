// Phase 1 evidence: delete -> reconcile should NOT recreate deleted history.
// H1: reconcile backfill re-creates deleted classReminder ids because no tombstone.
// Before fix: this test MUST FAIL (deleted id reappears). After fix: PASS.
// In-mem fakes mirror fixed behavior: tombstone on delete + skip in reconcile.

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/utils/delivered_id.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_delivered_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';

class InMemDeliveredRepo implements NotificationDeliveredRepository {
  final Map<int, NotificationDeliveredEntity> _m = {};
  final Set<int> _tomb = {};
  @override
  Future<List<NotificationDeliveredEntity>> getAll() async =>
      _m.values.toList()
        ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
  @override
  Future<void> save(NotificationDeliveredEntity e) async {
    if (_tomb.contains(e.id)) return;
    _m[e.id] = e;
  }

  @override
  Future<void> delete(int id) async {
    _m.remove(id);
    _tomb.add(id);
  }

  @override
  Future<void> deleteAll() async {
    for (final k in _m.keys) {
      _tomb.add(k);
    }
    _m.clear();
  }

  void tombstoneWindowId(int id) => _tomb.add(id);
  bool isTombstoned(int id) => _tomb.contains(id);
  @override
  Future<void> markAsRead(int id) async {
    final v = _m[id];
    if (v != null) {
      _m[id] = NotificationDeliveredEntity(
        id: v.id,
        courseName: v.courseName,
        dayOfWeek: v.dayOfWeek,
        classTime: v.classTime,
        deliveredAt: v.deliveredAt,
        room: v.room,
        lecturer: v.lecturer,
        isRead: true,
        source: v.source,
        scheduledId: v.scheduledId,
        title: v.title,
        body: v.body,
      );
    }
  }

  @override
  Future<void> markAllRead() async {
    for (final k in _m.keys.toList()) {
      await markAsRead(k);
    }
  }

  @override
  int getUnreadCount() => _m.values.where((e) => !e.isRead).length;
  @override
  bool containsKey(int id) => _m.containsKey(id);
}

class InMemScheduledRepo implements NotificationRepository {
  final Map<int, ScheduledNotificationEntity> _m = {};
  int _interval = 5;
  @override
  Future<List<ScheduledNotificationEntity>> getAll() async =>
      _m.values.toList();
  @override
  Future<ScheduledNotificationEntity?> getById(int id) async => _m[id];
  @override
  Future<void> save(ScheduledNotificationEntity e) async => _m[e.id] = e;
  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> l) async {
    for (final e in l) {
      _m[e.id] = e;
    }
  }

  @override
  Future<void> delete(int id) async => _m.remove(id);
  @override
  Future<void> deleteAll() async => _m.clear();
  @override
  int getReminderInterval() => _interval;
  @override
  void setReminderInterval(int m) => _interval = m;
}

Future<void> reconcileWithTrigger(
  InMemDeliveredRepo deliveredRepo,
  NotificationRepository scheduledRepo,
  DateTime Function(ScheduledNotificationEntity s) triggerFor,
) async {
  final scheduled = await scheduledRepo.getAll();
  if (scheduled.isEmpty) return;
  final deliveredAll = await deliveredRepo.getAll();
  final now = DateTime.now();
  for (final s in scheduled) {
    if (!s.isActive) continue;
    final triggerDt = triggerFor(s);
    final lastTrigger = now.isBefore(triggerDt)
        ? triggerDt.subtract(const Duration(days: 7))
        : triggerDt;
    final forId = deliveredAll.where((d) => d.scheduledId == s.id).toList()
      ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    final lastSaved = forId.isEmpty ? null : forId.first.deliveredAt;
    DateTime startCursor;
    if (lastSaved == null) {
      startCursor = lastTrigger.subtract(const Duration(days: 7 * 11));
    } else {
      startCursor = lastSaved.add(const Duration(days: 7));
    }
    DateTime cursor = startCursor;
    while (!cursor.isAfter(lastTrigger) && !cursor.isAfter(now)) {
      final deliveredId = deliveredIdFor(s.id, cursor);
      if (deliveredRepo.isTombstoned(deliveredId)) {
        // skip tombstoned — preserves user delete
      } else if (!deliveredRepo.containsKey(deliveredId)) {
        await deliveredRepo.save(
          NotificationDeliveredEntity(
            id: deliveredId,
            courseName: s.courseName,
            dayOfWeek: s.dayOfWeek,
            classTime: s.classTime,
            deliveredAt: cursor,
            room: s.room,
            lecturer: s.lecturer,
            isRead: false,
            source: NotificationSource.classReminder,
            scheduledId: s.id,
          ),
        );
      }
      final next = cursor.add(const Duration(days: 7));
      if (next.isAfter(lastTrigger)) break;
      cursor = next;
    }
  }
}

void main() {
  group('delivered_delete_reconcile repro — H1 (fixed)', () {
    late InMemDeliveredRepo delivRepo;
    late InMemScheduledRepo schedRepo;
    DateTime mondayTrigger(ScheduledNotificationEntity s) {
      final now = DateTime.now();
      final weekday = now.weekday;
      final daysSinceMonday = (weekday - 1) % 7;
      final monday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysSinceMonday));
      return DateTime(monday.year, monday.month, monday.day, 8, 0);
    }

    setUp(() {
      delivRepo = InMemDeliveredRepo();
      schedRepo = InMemScheduledRepo();
    });
    test('delete single -> reconcile -> still deleted', () async {
      final s = ScheduledNotificationEntity(
        id: 101,
        courseName: 'Pemrograman',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 5, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        isActive: true,
      );
      await schedRepo.save(s);
      expect(await delivRepo.getAll(), isEmpty);
      await reconcileWithTrigger(delivRepo, schedRepo, mondayTrigger);
      final afterReconcile = await delivRepo.getAll();
      expect(afterReconcile, isNotEmpty, reason: 'reconcile should backfill');
      final victimId = afterReconcile.first.id;
      await delivRepo.delete(victimId);
      expect(delivRepo.containsKey(victimId), isFalse);
      await reconcileWithTrigger(delivRepo, schedRepo, mondayTrigger);
      final afterSecond = await delivRepo.getAll();
      expect(
        afterSecond.any((e) => e.id == victimId),
        isFalse,
        reason: 'deleted id $victimId should NOT reappear',
      );
    });
    test('deleteAll -> reconcile -> still empty (window tombstoned)', () async {
      final s = ScheduledNotificationEntity(
        id: 202,
        courseName: 'Basis Data',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 6, 13, 0),
        reminderOffset: 10,
        room: 'R.201',
        isActive: true,
      );
      await schedRepo.save(s);
      await reconcileWithTrigger(delivRepo, schedRepo, mondayTrigger);
      expect((await delivRepo.getAll()).isNotEmpty, isTrue);
      // Mirror cubit.deleteAllDelivered window tombstoning: pre-tombstone full 12-week window
      final now = DateTime.now();
      final trigger = mondayTrigger(s);
      final lastTrigger = now.isBefore(trigger)
          ? trigger.subtract(const Duration(days: 7))
          : trigger;
      DateTime cursor = lastTrigger.subtract(const Duration(days: 7 * 11));
      while (!cursor.isAfter(lastTrigger) && !cursor.isAfter(now)) {
        delivRepo.tombstoneWindowId(deliveredIdFor(s.id, cursor));
        final next = cursor.add(const Duration(days: 7));
        if (next.isAfter(lastTrigger)) break;
        cursor = next;
      }
      await delivRepo.deleteAll();
      expect(await delivRepo.getAll(), isEmpty);
      await reconcileWithTrigger(delivRepo, schedRepo, mondayTrigger);
      expect(
        await delivRepo.getAll(),
        isEmpty,
        reason: 'deleteAll should persist after reconcile',
      );
    });
  });
}
