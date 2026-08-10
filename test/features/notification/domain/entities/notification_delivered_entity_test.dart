import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';

void main() {
  group('NotificationDeliveredEntity', () {
    test('equality holds for identical fields', () {
      final a = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
        lecturer: 'Dr. Budi',
      );
      final b = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
        lecturer: 'Dr. Budi',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when id differs', () {
      final a = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
      );
      final b = NotificationDeliveredEntity(
        id: 2,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when lecturer differs', () {
      final a = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
        lecturer: 'Dr. Budi',
      );
      final b = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
        lecturer: 'Dr. Ani',
      );
      expect(a, isNot(equals(b)));
    });

    test('null lecturer equals null lecturer', () {
      final a = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
      );
      final b = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
      );
      expect(a, equals(b));
    });
  });
}
