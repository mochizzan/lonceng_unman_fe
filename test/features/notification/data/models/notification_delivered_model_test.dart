import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/notification_delivered_model.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';

void main() {
  group('NotificationDeliveredModel', () {
    test('fromEntity preserves all fields', () {
      final entity = NotificationDeliveredEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        deliveredAt: DateTime(2026, 1, 1, 7, 55),
        room: 'R.301',
        lecturer: 'Dr. Budi',
      );

      final model = NotificationDeliveredModel.fromEntity(entity);

      expect(model.id, 1);
      expect(model.courseName, 'Algoritma');
      expect(model.dayOfWeek, 'Senin');
      expect(model.classTime, DateTime(2026, 1, 1, 8, 0));
      expect(model.deliveredAt, DateTime(2026, 1, 1, 7, 55));
      expect(model.room, 'R.301');
      expect(model.lecturer, 'Dr. Budi');
    });

    test('toEntity preserves all fields', () {
      final model = NotificationDeliveredModel(
        id: 2,
        courseName: 'Basis Data',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 2, 13, 0),
        deliveredAt: DateTime(2026, 1, 2, 12, 55),
        room: 'R.201',
        lecturer: 'Dr. Ani',
      );

      final entity = model.toEntity();

      expect(entity.id, 2);
      expect(entity.courseName, 'Basis Data');
      expect(entity.dayOfWeek, 'Selasa');
      expect(entity.classTime, DateTime(2026, 1, 2, 13, 0));
      expect(entity.deliveredAt, DateTime(2026, 1, 2, 12, 55));
      expect(entity.room, 'R.201');
      expect(entity.lecturer, 'Dr. Ani');
    });

    test('roundtrip preserves entity equality', () {
      final original = NotificationDeliveredEntity(
        id: 3,
        courseName: 'Matematika',
        dayOfWeek: 'Rabu',
        classTime: DateTime(2026, 1, 3, 10, 0),
        deliveredAt: DateTime(2026, 1, 3, 9, 55),
        room: 'R.101',
      );

      final model = NotificationDeliveredModel.fromEntity(original);
      final roundtripped = model.toEntity();

      expect(roundtripped, equals(original));
    });

    test('handles null lecturer', () {
      final entity = NotificationDeliveredEntity(
        id: 4,
        courseName: 'Fisika',
        dayOfWeek: 'Kamis',
        classTime: DateTime(2026, 1, 4, 14, 0),
        deliveredAt: DateTime(2026, 1, 4, 13, 55),
        room: 'R.401',
      );

      final model = NotificationDeliveredModel.fromEntity(entity);
      expect(model.lecturer, isNull);

      final roundtripped = model.toEntity();
      expect(roundtripped.lecturer, isNull);
      expect(roundtripped, equals(entity));
    });
  });
}
