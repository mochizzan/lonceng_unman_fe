import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

/// Repro untuk bug: dot notifikasi Home selalu merah meski riwayat kosong.
/// FIX: dot = unreadCount > 0 saja. Legacy OR (visibleEmpty && active && !viewed) dihapus.
///
/// Test ini harus HIJAU setelah fix. Sebelum fix ia MERAH (Expected false Actual true).

bool computeHasUnseenFixed(NotificationState s) {
  // Mirrors FIXED HomePage: hasUnseen = unreadCount > 0
  return s.unreadCount > 0;
}

bool computeHasDot(NotificationState s, bool hasUnseenNotifications) {
  return s.unreadCount > 0 || hasUnseenNotifications;
}

void main() {
  group('dot bug — FIXED (unreadCount only)', () {
    test('fresh install: future optimistic -> dot MATI', () {
      final now = DateTime.now();
      final state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: [
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'Algoritma',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.301',
            isActive: true,
          ),
        ],
        delivered: [
          NotificationDeliveredEntity(
            id: 99,
            courseName: 'Algoritma',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            deliveredAt: now.add(const Duration(days: 3)),
            room: 'R.301',
            isRead: false,
            source: NotificationSource.classReminder,
            scheduledId: 1,
          ),
        ],
        historyViewed: false,
      );

      expect(state.visibleDelivered, isEmpty);
      expect(state.unreadCount, 0);
      final hasUnseen = computeHasUnseenFixed(state);
      final hasDot = computeHasDot(state, hasUnseen);
      expect(hasUnseen, isFalse);
      expect(hasDot, isFalse, reason: 'dot harus mati saat visible kosong');
    });

    test('delivered kosong tanpa active — dot MATI', () {
      const state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: [],
        delivered: [],
        historyViewed: false,
      );
      final hasUnseen = computeHasUnseenFixed(state);
      expect(computeHasDot(state, hasUnseen), isFalse);
    });

    test('visible unread >0 — dot MENYALA', () {
      final now = DateTime.now();
      final state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: [
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'Algoritma',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.301',
            isActive: true,
          ),
        ],
        delivered: [
          NotificationDeliveredEntity(
            id: 100,
            courseName: 'Algoritma',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            deliveredAt: now.subtract(const Duration(hours: 1)),
            room: 'R.301',
            isRead: false,
            source: NotificationSource.classReminder,
            scheduledId: 1,
          ),
        ],
        historyViewed: false,
      );
      expect(state.unreadCount, 1);
      expect(computeHasDot(state, computeHasUnseenFixed(state)), isTrue);
    });

    test('visible semua read — dot MATI', () {
      final now = DateTime.now();
      final state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: [
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'Algoritma',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.301',
            isActive: true,
          ),
        ],
        delivered: [
          NotificationDeliveredEntity(
            id: 101,
            courseName: 'Algoritma',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            deliveredAt: now.subtract(const Duration(hours: 1)),
            room: 'R.301',
            isRead: true,
            source: NotificationSource.classReminder,
            scheduledId: 1,
          ),
        ],
        historyViewed: true,
      );
      expect(state.unreadCount, 0);
      expect(computeHasDot(state, computeHasUnseenFixed(state)), isFalse);
    });

    test('after markAllRead (visible jadi read) — dot MATI', () {
      final now = DateTime.now();
      final before = NotificationState(
        status: NotificationStatus.loaded,
        notifications: [
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'A',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R1',
            isActive: true,
          ),
        ],
        delivered: [
          NotificationDeliveredEntity(
            id: 200,
            courseName: 'A',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            deliveredAt: now.subtract(const Duration(minutes: 5)),
            room: 'R1',
            isRead: false,
            source: NotificationSource.classReminder,
            scheduledId: 1,
          ),
        ],
        historyViewed: false,
      );
      expect(computeHasDot(before, computeHasUnseenFixed(before)), isTrue);
      final after = NotificationState(
        status: before.status,
        notifications: before.notifications,
        delivered: before.delivered
            .map(
              (d) => NotificationDeliveredEntity(
                id: d.id,
                courseName: d.courseName,
                dayOfWeek: d.dayOfWeek,
                classTime: d.classTime,
                deliveredAt: d.deliveredAt,
                room: d.room,
                lecturer: d.lecturer,
                isRead: true,
                source: d.source,
                scheduledId: d.scheduledId,
              ),
            )
            .toList(),
        historyViewed: before.historyViewed,
      );
      expect(computeHasDot(after, computeHasUnseenFixed(after)), isFalse);
    });

    test('after deleteAll (visible kosong, no unread) — dot MATI', () {
      final state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: [
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'A',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R1',
            isActive: true,
          ),
        ],
        delivered: const [],
        historyViewed: false,
      );
      expect(computeHasDot(state, computeHasUnseenFixed(state)), isFalse);
    });
  });
}
