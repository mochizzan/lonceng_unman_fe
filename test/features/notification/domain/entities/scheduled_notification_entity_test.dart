import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

void main() {
  group('ScheduledNotificationEntity', () {
    group('computeId', () {
      test('returns consistent positive integer', () {
        final id1 = ScheduledNotificationEntity.computeId(
          'Algoritma',
          'Senin',
          8,
        );
        final id2 = ScheduledNotificationEntity.computeId(
          'Algoritma',
          'Senin',
          8,
        );
        expect(id1, id2);
        expect(id1, greaterThan(0));
      });

      test('returns different IDs for different courses', () {
        final id1 = ScheduledNotificationEntity.computeId(
          'Algoritma',
          'Senin',
          8,
        );
        final id2 = ScheduledNotificationEntity.computeId(
          'Basis Data',
          'Senin',
          8,
        );
        expect(id1, isNot(equals(id2)));
      });

      test('returns different IDs for different days', () {
        final id1 = ScheduledNotificationEntity.computeId(
          'Algoritma',
          'Senin',
          8,
        );
        final id2 = ScheduledNotificationEntity.computeId(
          'Algoritma',
          'Selasa',
          8,
        );
        expect(id1, isNot(equals(id2)));
      });

      test('returns different IDs for different hours', () {
        final id1 = ScheduledNotificationEntity.computeId(
          'Algoritma',
          'Senin',
          8,
        );
        final id2 = ScheduledNotificationEntity.computeId(
          'Algoritma',
          'Senin',
          10,
        );
        expect(id1, isNot(equals(id2)));
      });
    });

    group('equality', () {
      test('equal instances are considered equal', () {
        final entity1 = ScheduledNotificationEntity(
          id: 1,
          courseName: 'Algoritma',
          dayOfWeek: 'Senin',
          classTime: DateTime(2026, 1, 1, 8, 0),
          reminderOffset: 5,
          room: 'R.301',
          isActive: true,
        );
        final entity2 = ScheduledNotificationEntity(
          id: 1,
          courseName: 'Algoritma',
          dayOfWeek: 'Senin',
          classTime: DateTime(2026, 1, 1, 8, 0),
          reminderOffset: 5,
          room: 'R.301',
          isActive: true,
        );
        expect(entity1, equals(entity2));
        expect(entity1.hashCode, entity2.hashCode);
      });

      test('inequality works for different fields', () {
        final entity1 = ScheduledNotificationEntity(
          id: 1,
          courseName: 'Algoritma',
          dayOfWeek: 'Senin',
          classTime: DateTime(2026, 1, 1, 8, 0),
          reminderOffset: 5,
          room: 'R.301',
          isActive: true,
        );
        final entity2 = ScheduledNotificationEntity(
          id: 1,
          courseName: 'Algoritma',
          dayOfWeek: 'Senin',
          classTime: DateTime(2026, 1, 1, 8, 0),
          reminderOffset: 5,
          room: 'R.301',
          isActive: false,
        );
        expect(entity1, isNot(equals(entity2)));
      });
    });

    test('lecturer is nullable', () {
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        lecturer: null,
        isActive: true,
      );
      expect(entity.lecturer, isNull);
    });

    group('fromJadwalEntity', () {
      test('converts JadwalEntity schedule items to notification entities', () {
        final jadwal = JadwalEntity(
          selectedDay: 'Senin',
          days: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
          scheduleItems: [
            JadwalScheduleItem(
              courseName: 'Algoritma',
              startTime: DateTime(2026, 8, 10, 8, 0),
              endTime: DateTime(2026, 8, 10, 9, 40),
              room: 'R.301',
              sks: '3',
              status: JadwalScheduleStatus.upcoming,
              lecturer: 'Dr. Budi',
            ),
            JadwalScheduleItem(
              courseName: 'Basis Data',
              startTime: DateTime(2026, 8, 10, 10, 0),
              endTime: DateTime(2026, 8, 10, 11, 40),
              room: 'R.205',
              sks: '3',
              status: JadwalScheduleStatus.upcoming,
            ),
          ],
        );

        final notifications = ScheduledNotificationEntity.fromJadwalEntity(
          jadwal,
        );

        expect(notifications, hasLength(2));

        final first = notifications[0];
        expect(first.courseName, 'Algoritma');
        expect(first.dayOfWeek, 'Senin');
        expect(first.classTime, DateTime(2026, 8, 10, 8, 0));
        expect(first.room, 'R.301');
        expect(first.lecturer, 'Dr. Budi');
        expect(first.reminderOffset, 5);
        expect(first.isActive, isTrue);
        expect(
          first.id,
          ScheduledNotificationEntity.computeId('Algoritma', 'Senin', 8),
        );

        final second = notifications[1];
        expect(second.courseName, 'Basis Data');
        expect(second.lecturer, isNull);
        expect(second.room, 'R.205');
      });

      test('respects custom default parameters', () {
        final jadwal = JadwalEntity(
          selectedDay: 'Selasa',
          days: ['Selasa'],
          scheduleItems: [
            JadwalScheduleItem(
              courseName: 'Algoritma',
              startTime: DateTime(2026, 8, 11, 14, 0),
              endTime: DateTime(2026, 8, 11, 15, 40),
              room: 'R.301',
              sks: '3',
              status: JadwalScheduleStatus.upcoming,
            ),
          ],
        );

        final notifications = ScheduledNotificationEntity.fromJadwalEntity(
          jadwal,
          defaultReminderOffset: 15,
          defaultIsActive: false,
        );

        expect(notifications, hasLength(1));
        expect(notifications[0].reminderOffset, 15);
        expect(notifications[0].isActive, isFalse);
        expect(notifications[0].dayOfWeek, 'Selasa');
      });

      test('returns empty list for empty scheduleItems', () {
        final jadwal = JadwalEntity(
          selectedDay: 'Senin',
          days: ['Senin'],
          scheduleItems: [],
        );

        final notifications = ScheduledNotificationEntity.fromJadwalEntity(
          jadwal,
        );

        expect(notifications, isEmpty);
      });
    });
  });
}
