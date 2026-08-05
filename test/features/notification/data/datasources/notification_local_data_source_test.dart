// test/features/notification/data/datasources/notification_local_data_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';

void main() {
  late Box<ScheduledNotificationModel> notificationsBox;
  late Box<int> settingsBox;
  late NotificationLocalDataSource dataSource;

  setUpAll(() async {
    Hive.init('.');
    Hive.registerAdapter(ScheduledNotificationModelAdapter());
  });

  setUp(() async {
    // Use unique box names per test to avoid state leakage
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    notificationsBox = await Hive.openBox<ScheduledNotificationModel>(
      'test_notifications_$timestamp',
    );
    settingsBox = await Hive.openBox<int>('test_settings_$timestamp');
    // Clear any stale data from previous test runs
    await notificationsBox.clear();
    await settingsBox.clear();
    dataSource = NotificationLocalDataSource(
      notificationsBox: notificationsBox,
      settingsBox: settingsBox,
    );
  });

  tearDown(() async {
    await notificationsBox.close();
    await settingsBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  ScheduledNotificationModel _createModel(int id) {
    return ScheduledNotificationModel(
      id: id,
      courseName: 'Course $id',
      dayOfWeek: 'Senin',
      classTime: DateTime(2026, 1, 1, 8 + id, 0),
      reminderOffset: 5,
      room: 'Room $id',
      isActive: true,
    );
  }

  group('NotificationLocalDataSource', () {
    test('getAll returns empty list initially', () {
      expect(dataSource.getAll(), isEmpty);
    });

    test('save stores notification and getAll retrieves it', () async {
      final model = _createModel(1);
      await dataSource.save(model);
      final result = dataSource.getAll();
      expect(result, hasLength(1));
      expect(result.first.id, 1);
    });

    test('getById returns correct notification', () async {
      await dataSource.save(_createModel(1));
      await dataSource.save(_createModel(2));
      final result = dataSource.getById(2);
      expect(result, isNotNull);
      expect(result!.id, 2);
    });

    test('getById returns null for nonexistent ID', () {
      expect(dataSource.getById(999), isNull);
    });

    test('save overwrites existing notification with same ID', () async {
      await dataSource.save(_createModel(1));
      final updated = ScheduledNotificationModel(
        id: 1,
        courseName: 'Updated Course',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 2, 9, 0),
        reminderOffset: 10,
        room: 'New Room',
        isActive: false,
      );
      await dataSource.save(updated);
      final result = dataSource.getById(1);
      expect(result!.courseName, 'Updated Course');
      expect(result.isActive, false);
    });

    test('saveAll stores multiple notifications', () async {
      await dataSource.saveAll([
        _createModel(1),
        _createModel(2),
        _createModel(3),
      ]);
      expect(dataSource.getAll(), hasLength(3));
    });

    test('delete removes notification by ID', () async {
      await dataSource.save(_createModel(1));
      await dataSource.save(_createModel(2));
      await dataSource.delete(1);
      expect(dataSource.getById(1), isNull);
      expect(dataSource.getById(2), isNotNull);
    });

    test('deleteAll clears all notifications', () async {
      await dataSource.saveAll([_createModel(1), _createModel(2)]);
      await dataSource.deleteAll();
      expect(dataSource.getAll(), isEmpty);
    });

    test('getReminderInterval returns default 5 when not set', () {
      expect(dataSource.getReminderInterval(), 5);
    });

    test(
      'setReminderInterval persists and getReminderInterval retrieves',
      () async {
        await dataSource.setReminderInterval(15);
        expect(dataSource.getReminderInterval(), 15);
      },
    );
  });
}
