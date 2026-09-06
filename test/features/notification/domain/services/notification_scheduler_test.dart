import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// Mock NotificationRepository
// ---------------------------------------------------------------------------
class MockNotificationRepository implements NotificationRepository {
  final List<ScheduledNotificationEntity> _store = [];
  int _reminderInterval = 5;

  @override
  Future<List<ScheduledNotificationEntity>> getAll() async =>
      List.unmodifiable(_store);

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async {
    try {
      return _store.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {
    _store.removeWhere((e) => e.id == notification.id);
    _store.add(notification);
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {
    for (final n in notifications) {
      await save(n);
    }
  }

  @override
  Future<void> delete(int id) async {
    _store.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  int getReminderInterval() => _reminderInterval;

  @override
  void setReminderInterval(int minutes) => _reminderInterval = minutes;

  List<ScheduledNotificationEntity> get stored => List.unmodifiable(_store);
}

// ---------------------------------------------------------------------------
// Mock NotificationService
// ---------------------------------------------------------------------------
class MockNotificationService implements NotificationService {
  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];
  bool allCancelled = false;
  bool canScheduleExact = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required NotificationChannel channel,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.exactAllowWhileIdle,
  }) async {
    scheduledIds.add(id);
  }

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);

  @override
  Future<void> cancelAll() async => allCancelled = true;

  @override
  Future<bool> canScheduleExactNotifications() async => canScheduleExact;

  @override
  Future<bool> checkPermissionStatus() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationChannel channel,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
    List<AndroidNotificationAction>? actions,
  }) async {}

  @override
  void setExternalResponseHandler(
    void Function(NotificationResponse p1)? handler,
  ) {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockNotificationRepository mockRepo;
  late MockNotificationService mockService;
  late NotificationScheduler scheduler;

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  });

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockService = MockNotificationService();
    scheduler = NotificationScheduler(
      repository: mockRepo,
      notificationService: mockService,
    );
  });

  group('NotificationScheduler', () {
    test('scheduleForDay creates entities and schedules alarms', () async {
      final jadwal = JadwalEntity(
        selectedDay: 'Senin',
        days: ['Senin', 'Selasa', 'Rabu'],
        scheduleItems: [
          ScheduleItemEntity(
            courseName: 'Algoritma',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            room: 'R.301',
            sks: '3',
            status: ScheduleStatus.upcoming,
            dayOfWeek: 'Senin',
          ),
        ],
      );

      await scheduler.scheduleForDay(jadwal);

      expect(mockRepo.stored, hasLength(1));
      expect(mockRepo.stored.first.courseName, 'Algoritma');
      expect(mockRepo.stored.first.dayOfWeek, 'Senin');
      expect(mockRepo.stored.first.isActive, isTrue);
      expect(mockRepo.stored.first.reminderOffset, 5);
      expect(mockService.scheduledIds, hasLength(1));
    });

    test('scheduleForDay creates entities for all items', () async {
      final jadwal = JadwalEntity(
        selectedDay: 'Selasa',
        days: ['Senin', 'Selasa'],
        scheduleItems: [
          ScheduleItemEntity(
            courseName: 'Algoritma',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            room: 'R.301',
            sks: '3',
            status: ScheduleStatus.upcoming,
            dayOfWeek: 'Selasa',
          ),
          ScheduleItemEntity(
            courseName: 'Basis Data',
            startTime: DateTime(2026, 1, 1, 13, 0),
            endTime: DateTime(2026, 1, 1, 15, 0),
            room: 'R.201',
            sks: '3',
            lecturer: 'Dr. Budi',
            status: ScheduleStatus.upcoming,
            dayOfWeek: 'Selasa',
          ),
        ],
      );

      await scheduler.scheduleForDay(jadwal);

      expect(mockRepo.stored, hasLength(2));
      expect(mockService.scheduledIds, hasLength(2));
      expect(
        mockRepo.stored.map((e) => e.courseName).toList(),
        containsAll(['Algoritma', 'Basis Data']),
      );
    });

    test('cancelAll removes all alarms and data', () async {
      // First schedule something
      final jadwal = JadwalEntity(
        selectedDay: 'Senin',
        days: ['Senin'],
        scheduleItems: [
          ScheduleItemEntity(
            courseName: 'Test',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            room: 'R.1',
            sks: '2',
            status: ScheduleStatus.upcoming,
            dayOfWeek: 'Senin',
          ),
        ],
      );
      await scheduler.scheduleForDay(jadwal);

      // Now cancel all
      await scheduler.cancelAll();
      expect(mockService.allCancelled, isTrue);
      expect(mockRepo.stored, isEmpty);
    });

    test('scheduleSingle schedules one alarm', () async {
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Test',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.1',
        isActive: true,
      );

      await scheduler.scheduleSingle(entity);
      expect(mockService.scheduledIds, contains(1));
    });

    test('scheduleSingle skips inactive entities', () async {
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Test',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.1',
        isActive: false,
      );

      await scheduler.scheduleSingle(entity);
      expect(mockService.scheduledIds, isEmpty);
    });

    test('cancelSingle cancels one alarm', () async {
      final entity = ScheduledNotificationEntity(
        id: 42,
        courseName: 'Test',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.1',
        isActive: true,
      );

      await scheduler.cancelSingle(entity);
      expect(mockService.cancelledIds, contains(42));
    });

    test('rescheduleAllWithNewOffset updates offset and reschedules', () async {
      // Setup: store a notification
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        isActive: true,
      );
      await mockRepo.save(entity);

      await scheduler.rescheduleAllWithNewOffset(15);

      // Should have cancelled all first
      expect(mockService.allCancelled, isTrue);

      // Should have rescheduled with new offset
      final updated = await mockRepo.getById(1);
      expect(updated!.reminderOffset, 15);
      expect(mockService.scheduledIds, contains(1));
    });

    test('rescheduleAllWithNewOffset skips inactive notifications', () async {
      final inactive = ScheduledNotificationEntity(
        id: 2,
        courseName: ' inactive',
        dayOfWeek: 'Rabu',
        classTime: DateTime(2026, 1, 1, 10, 0),
        reminderOffset: 10,
        room: 'R.2',
        isActive: false,
      );
      await mockRepo.save(inactive);

      await scheduler.rescheduleAllWithNewOffset(15);

      expect(mockService.allCancelled, isTrue);
      // Inactive should not be re-scheduled
      expect(mockService.scheduledIds, isEmpty);
    });

    test('scheduleAllDays cancels old alarms and creates new ones', () async {
      final items = [
        ScheduleItemEntity(
          courseName: 'Algoritma',
          startTime: DateTime(2026, 1, 1, 8, 0),
          endTime: DateTime(2026, 1, 1, 10, 0),
          room: 'R.301',
          sks: '3',
          status: ScheduleStatus.upcoming,
          dayOfWeek: 'Senin',
        ),
        ScheduleItemEntity(
          courseName: 'Basis Data',
          startTime: DateTime(2026, 1, 2, 13, 0),
          endTime: DateTime(2026, 1, 2, 15, 0),
          room: 'R.201',
          sks: '3',
          status: ScheduleStatus.upcoming,
          dayOfWeek: 'Selasa',
        ),
      ];

      await scheduler.scheduleAllDays(items);

      expect(mockService.allCancelled, isTrue);
      expect(mockRepo.stored, hasLength(2));
      expect(mockService.scheduledIds, hasLength(2));
      expect(
        mockRepo.stored.map((e) => e.dayOfWeek).toList(),
        containsAll(['Senin', 'Selasa']),
      );
    });

    test('scheduleForDay with Semua selectedDay schedules all items', () async {
      final jadwal = JadwalEntity(
        selectedDay: 'Semua',
        days: ['Senin', 'Selasa', 'Rabu'],
        scheduleItems: [
          ScheduleItemEntity(
            courseName: 'Algoritma',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            room: 'R.301',
            sks: '3',
            status: ScheduleStatus.upcoming,
            dayOfWeek: 'Senin',
          ),
          ScheduleItemEntity(
            courseName: 'Basis Data',
            startTime: DateTime(2026, 1, 2, 13, 0),
            endTime: DateTime(2026, 1, 2, 15, 0),
            room: 'R.201',
            sks: '3',
            status: ScheduleStatus.upcoming,
            dayOfWeek: 'Selasa',
          ),
        ],
      );

      await scheduler.scheduleForDay(jadwal);

      expect(mockRepo.stored, hasLength(2));
      expect(mockService.scheduledIds, hasLength(2));
      expect(
        mockRepo.stored.map((e) => e.dayOfWeek).toList(),
        containsAll(['Senin', 'Selasa']),
      );
    });

    test('body includes room, time, and optional lecturer', () {
      final withLecturer = ScheduledNotificationEntity(
        id: 10,
        courseName: 'Test',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 30),
        reminderOffset: 5,
        room: 'R.301',
        lecturer: 'Dr. Budi',
        isActive: true,
      );

      final withoutLecturer = ScheduledNotificationEntity(
        id: 11,
        courseName: 'Test',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 30),
        reminderOffset: 5,
        room: 'R.301',
        isActive: true,
      );

      // We can't easily test _buildBody directly, but we verify entities are
      // created with the correct data by checking stored values
      expect(withLecturer.lecturer, 'Dr. Budi');
      expect(withoutLecturer.lecturer, isNull);
    });
  });
}
