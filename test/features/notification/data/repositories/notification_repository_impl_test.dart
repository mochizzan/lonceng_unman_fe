// test/features/notification/data/repositories/notification_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

void main() {
  late Box<ScheduledNotificationModel> notificationsBox;
  late Box<int> settingsBox;
  late NotificationLocalDataSource dataSource;
  late NotificationRepositoryImpl repository;

  final testEntity = ScheduledNotificationEntity(
    id: 1,
    courseName: 'Algoritma',
    dayOfWeek: 'Senin',
    classTime: DateTime(2026, 1, 1, 8, 0),
    reminderOffset: 5,
    room: 'R.301',
    lecturer: 'Dr. Budi',
    isActive: true,
  );

  setUpAll(() async {
    Hive.init('.');
    Hive.registerAdapter(ScheduledNotificationModelAdapter());
  });

  setUp(() async {
    notificationsBox = await Hive.openBox<ScheduledNotificationModel>(
      'repo_test_notifications',
    );
    settingsBox = await Hive.openBox<int>('repo_test_settings');
    await notificationsBox.clear();
    await settingsBox.clear();
    dataSource = NotificationLocalDataSource(
      notificationsBox: notificationsBox,
      settingsBox: settingsBox,
    );
    repository = NotificationRepositoryImpl(localDataSource: dataSource);
  });

  tearDown(() async {
    await notificationsBox.close();
    await settingsBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('NotificationRepositoryImpl', () {
    test('save and getAll roundtrip preserves entity', () async {
      await repository.save(testEntity);
      final result = await repository.getAll();
      expect(result, hasLength(1));
      expect(result.first, equals(testEntity));
    });

    test('getById returns correct entity', () async {
      await repository.save(testEntity);
      final result = await repository.getById(1);
      expect(result, equals(testEntity));
    });

    test('getById returns null for nonexistent', () {
      expect(repository.getById(999), completion(isNull));
    });

    test('delete removes entity', () async {
      await repository.save(testEntity);
      await repository.delete(1);
      expect(repository.getById(1), completion(isNull));
    });

    test('deleteAll clears all', () async {
      await repository.save(testEntity);
      await repository.deleteAll();
      expect(repository.getAll(), completion(isEmpty));
    });

    test('saveAll stores multiple entities', () async {
      final entity2 = ScheduledNotificationEntity(
        id: 2,
        courseName: 'Basis Data',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 2, 10, 0),
        reminderOffset: 10,
        room: 'R.201',
        isActive: true,
      );
      await repository.saveAll([testEntity, entity2]);
      final result = await repository.getAll();
      expect(result, hasLength(2));
    });

    test('getReminderInterval returns default 5', () {
      expect(repository.getReminderInterval(), 5);
    });

    test('setReminderInterval persists value', () {
      repository.setReminderInterval(15);
      expect(repository.getReminderInterval(), 15);
    });
  });
}
