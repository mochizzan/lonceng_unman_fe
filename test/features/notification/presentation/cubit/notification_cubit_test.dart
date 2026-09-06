import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

// Minimal mock repository for cubit tests
class MockNotificationRepository implements NotificationRepository {
  List<ScheduledNotificationEntity> _store = [];
  int _interval = 5;

  void setStore(List<ScheduledNotificationEntity> store) => _store = store;

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
    _store = [..._store.where((e) => e.id != notification.id), notification];
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {
    _store = notifications;
  }

  @override
  Future<void> delete(int id) async =>
      _store = _store.where((e) => e.id != id).toList();

  @override
  Future<void> deleteAll() async => _store = [];

  @override
  int getReminderInterval() => _interval;

  @override
  void setReminderInterval(int minutes) => _interval = minutes;
}

// Minimal mock scheduler
class MockNotificationScheduler implements NotificationScheduler {
  @override
  tz.TZDateTime computeTrigger(ScheduledNotificationEntity entity) {
    return tz.TZDateTime(tz.local, 2026, 1, 5, 8, 0);
  }

  bool scheduled = false;
  bool allCancelled = false;
  List<ScheduleItemEntity>? lastScheduleAllItems;

  @override
  Future<void> scheduleForDay(JadwalEntity jadwal) async => scheduled = true;

  @override
  Future<void> scheduleAllDays(List<ScheduleItemEntity> items) async {
    await cancelAll();
    lastScheduleAllItems = items;
  }

  @override
  Future<void> scheduleSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelAll() async => allCancelled = true;

  @override
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {}
}

// Minimal mock notification service
class MockNotificationService implements NotificationService {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> canScheduleExactNotifications() async => true;

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
  }) async {}

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

void main() {
  late MockNotificationRepository mockRepo;
  late MockNotificationScheduler mockScheduler;
  late MockNotificationService mockService;
  late NotificationCubit cubit;

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockScheduler = MockNotificationScheduler();
    mockService = MockNotificationService();
    cubit = NotificationCubit(
      scheduler: mockScheduler,
      repository: mockRepo,
      notificationService: mockService,
    );
  });

  tearDown(() => cubit.close());

  group('NotificationCubit', () {
    blocTest<NotificationCubit, NotificationState>(
      'emits [loading, loaded] when loadNotifications succeeds',
      build: () {
        mockRepo.setStore([
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'Test',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.1',
            isActive: true,
          ),
        ]);
        return cubit;
      },
      act: (cubit) => cubit.loadNotifications(),
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        predicate<NotificationState>(
          (s) =>
              s.status == NotificationStatus.loaded &&
              s.notifications.length == 1 &&
              s.reminderIntervalMinutes == 5,
        ),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits [loading, loaded] when scheduleFromJadwal succeeds',
      build: () => cubit,
      act: (cubit) async {
        mockRepo.setStore([]);
        await cubit.scheduleFromJadwal(
          const JadwalEntity(
            selectedDay: 'Senin',
            days: ['Senin'],
            scheduleItems: [],
          ),
        );
      },
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        predicate<NotificationState>(
          (s) =>
              s.status == NotificationStatus.loaded && s.notifications.isEmpty,
        ),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits updated notifications when toggleNotification is called',
      build: () {
        mockRepo.setStore([
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'Test',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.1',
            isActive: true,
          ),
        ]);
        return cubit;
      },
      act: (cubit) => cubit.toggleNotification(1),
      expect: () => [
        predicate<NotificationState>(
          (s) => s.notifications.first.isActive == false,
        ),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits updated interval when updateReminderInterval is called',
      build: () => cubit,
      act: (cubit) => cubit.updateReminderInterval(15),
      expect: () => [
        predicate<NotificationState>((s) => s.reminderIntervalMinutes == 15),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits empty list when cancelAll is called',
      build: () {
        mockRepo.setStore([
          ScheduledNotificationEntity(
            id: 1,
            courseName: 'Test',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.1',
            isActive: true,
          ),
        ]);
        return cubit;
      },
      act: (cubit) => cubit.cancelAll(),
      expect: () => [
        predicate<NotificationState>((s) => s.notifications.isEmpty),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'scheduleAll schedules notifications for all items',
      build: () {
        mockRepo.setStore([]);
        return cubit;
      },
      act: (cubit) async {
        await cubit.scheduleAll([
          ScheduleItemEntity(
            courseName: 'Algoritma',
            room: 'R.301',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            dayOfWeek: 'Senin',
          ),
          ScheduleItemEntity(
            courseName: 'Basis Data',
            room: 'R.201',
            startTime: DateTime(2026, 1, 2, 13, 0),
            endTime: DateTime(2026, 1, 2, 15, 0),
            dayOfWeek: 'Selasa',
          ),
        ]);
      },
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        predicate<NotificationState>(
          (s) => s.status == NotificationStatus.loaded,
        ),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'scheduleAll cancels previous alarms before creating new ones',
      build: () {
        mockRepo.setStore([]);
        return cubit;
      },
      act: (cubit) async {
        await cubit.scheduleAll([
          ScheduleItemEntity(
            courseName: 'Test',
            room: 'R.1',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            dayOfWeek: 'Senin',
          ),
        ]);
      },
      verify: (_) {
        expect(mockScheduler.allCancelled, isTrue);
        expect(mockScheduler.lastScheduleAllItems, hasLength(1));
      },
    );

    blocTest<NotificationCubit, NotificationState>(
      'scheduleAll emits error when permission denied',
      build: () {
        // Use a service that denies permission
        final deniedService = _DeniedPermissionService();
        final deniedCubit = NotificationCubit(
          scheduler: mockScheduler,
          repository: mockRepo,
          notificationService: deniedService,
        );
        return deniedCubit;
      },
      act: (cubit) async {
        await cubit.scheduleAll([
          ScheduleItemEntity(
            courseName: 'Test',
            room: 'R.1',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            dayOfWeek: 'Senin',
          ),
        ]);
      },
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        predicate<NotificationState>(
          (s) => s.notificationPermissionDenied == true,
        ),
        predicate<NotificationState>(
          (s) =>
              s.status == NotificationStatus.error &&
              s.notificationPermissionDenied == true,
        ),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'markHistoryViewed sets historyViewed to true',
      build: () => cubit,
      act: (cubit) async {
        await cubit.loadNotifications();
        cubit.markHistoryViewed();
      },
      verify: (cubit) {
        expect(cubit.state.historyViewed, isTrue);
      },
    );
  });
}

/// Mock service that denies notification permission.
class _DeniedPermissionService implements NotificationService {
  @override
  Future<bool> checkPermissionStatus() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> canScheduleExactNotifications() async => true;

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
  }) async {}

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
