import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/pages/notification_history_page.dart';
import 'package:timezone/timezone.dart' as tz;

// --- Minimal fakes ---

class FakeNotificationRepository implements NotificationRepository {
  List<ScheduledNotificationEntity> _store = [];
  int _interval = 5;

  @override
  Future<List<ScheduledNotificationEntity>> getAll() async =>
      List.unmodifiable(_store);

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async =>
      _store.where((e) => e.id == id).firstOrNull;

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {
    _store = [..._store.where((e) => e.id != notification.id), notification];
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async =>
      _store = notifications;

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

class FakeNotificationScheduler implements NotificationScheduler {
  @override
  tz.TZDateTime computeTrigger(ScheduledNotificationEntity entity) {
    return tz.TZDateTime(tz.local, 2026, 1, 5, 8, 0);
  }

  @override
  Future<void> scheduleForDay(JadwalEntity jadwal) async {}

  @override
  Future<void> scheduleAllDays(List<ScheduleItemEntity> items) async {}

  @override
  Future<void> scheduleSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {}

  @override
  Future<int> restoreAll() async => 0;
}

class FakeNotificationService implements NotificationService {
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

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => [];
}

// --- Tests ---

void main() {
  late FakeNotificationRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeNotificationRepository();
  });

  Widget buildTestable({
    List<ScheduledNotificationEntity>? initialNotifications,
  }) {
    if (initialNotifications != null) {
      fakeRepo._store = initialNotifications;
    }
    return MaterialApp(
      home: BlocProvider(
        create: (_) => NotificationCubit(
          scheduler: FakeNotificationScheduler(),
          repository: fakeRepo,
          notificationService: FakeNotificationService(),
        )..loadNotifications(),
        child: const NotificationHistoryPage(),
      ),
    );
  }

  group('NotificationHistoryPage', () {
    testWidgets('renders empty state when no notifications', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      expect(find.text('Belum ada notifikasi'), findsOneWidget);
    });

    testWidgets('renders notification list when notifications exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          initialNotifications: [
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
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Algoritma'), findsOneWidget);
      expect(find.text('Senin • 08:00 • R.301'), findsOneWidget);
    });

    testWidgets('toggle switch calls cubit.toggleNotification', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          initialNotifications: [
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
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the switch
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // After toggle, notification should be inactive
      expect(find.text('Algoritma'), findsOneWidget);
    });
  });
}
