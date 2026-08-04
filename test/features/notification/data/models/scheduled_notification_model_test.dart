import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';

void main() {
  group('ScheduledNotificationModel', () {
    final entity = ScheduledNotificationEntity(
      id: 1,
      courseName: 'Algoritma Pemrograman',
      dayOfWeek: 'Senin',
      classTime: DateTime(2026, 1, 1, 8, 0),
      reminderOffset: 5,
      room: 'R.301 Gedung A',
      lecturer: 'Dr. Budi',
      isActive: true,
    );

    test('fromEntity creates model from entity', () {
      final model = ScheduledNotificationModel.fromEntity(entity);
      expect(model.id, 1);
      expect(model.courseName, 'Algoritma Pemrograman');
      expect(model.dayOfWeek, 'Senin');
      expect(model.classTime, DateTime(2026, 1, 1, 8, 0));
      expect(model.reminderOffset, 5);
      expect(model.room, 'R.301 Gedung A');
      expect(model.lecturer, 'Dr. Budi');
      expect(model.isActive, true);
    });

    test('toEntity converts model back to entity', () {
      final model = ScheduledNotificationModel.fromEntity(entity);
      final result = model.toEntity();
      expect(result, equals(entity));
    });

    test('roundtrip preserves all fields', () {
      final model = ScheduledNotificationModel.fromEntity(entity);
      final result = model.toEntity();
      expect(result.id, entity.id);
      expect(result.courseName, entity.courseName);
      expect(result.dayOfWeek, entity.dayOfWeek);
      expect(result.classTime, entity.classTime);
      expect(result.reminderOffset, entity.reminderOffset);
      expect(result.room, entity.room);
      expect(result.lecturer, entity.lecturer);
      expect(result.isActive, entity.isActive);
    });

    test('handles null lecturer', () {
      final entityNoLecturer = ScheduledNotificationEntity(
        id: 2,
        courseName: 'Basis Data',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 2, 10, 0),
        reminderOffset: 10,
        room: 'R.201',
        lecturer: null,
        isActive: true,
      );
      final model = ScheduledNotificationModel.fromEntity(entityNoLecturer);
      expect(model.lecturer, isNull);
      final result = model.toEntity();
      expect(result.lecturer, isNull);
    });
  });
}
