import 'package:flutter_test/flutter_test.dart';
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
  });
}
