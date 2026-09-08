// jadwal - Pull-to-refresh exploration v3
//
// Stub AcademicCacheService so triggerRefresh doesn't crash. Now we can
// observe pull-to-refresh behavior in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_event.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:timezone/timezone.dart' as tz;

class _JadwalRepoWith implements JadwalRepository {
  _JadwalRepoWith(this._items);
  final List<ScheduleItemEntity> _items;

  @override
  Future<JadwalEntity> getJadwal() async => JadwalEntity(
    selectedDay: 'Semua',
    days: const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Semua'],
    scheduleItems: _items,
  );
}

ScheduleItemEntity _mkItem(String day, int startHour) {
  const names = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  final idx = names.indexOf(day);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  final diff = (idx + 1 - base.weekday) % 7;
  final day0 = base.add(Duration(days: diff == 0 ? 7 : diff));
  return ScheduleItemEntity(
    courseName: 'Course $day #$startHour',
    startTime: day0.add(Duration(hours: startHour)),
    endTime: day0.add(Duration(hours: startHour + 1)),
    sks: '3',
    room: 'Room ${startHour}0$idx',
    lecturer: 'Dosen $day',
    status: ScheduleStatus.upcoming,
  );
}

/// Minimal AcademicCacheService stub that just returns null credentials,
/// which causes triggerRefresh to bail out before opening the overlay.
class _NoCredsCache extends AcademicCacheService {
  @override
  Future<Map<String, String>?> loadCredentials() async => null;
}

class _NotificationRepoEmpty implements NotificationRepository {
  @override
  Future<List<ScheduledNotificationEntity>> getAll() async => const [];

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async => null;

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {}

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  int getReminderInterval() => 5;

  @override
  void setReminderInterval(int minutes) {}
}

class _NoopNotificationScheduler implements NotificationScheduler {
  @override
  tz.TZDateTime computeTrigger(ScheduledNotificationEntity entity) {
    return tz.TZDateTime(tz.local, 2026, 1, 5, 8, 0);
  }

  @override
  Future<void> scheduleAllDays(List items) async {}

  @override
  Future<void> scheduleForDay(JadwalEntity jadwal) async {}

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

class _NoopNotificationService implements NotificationService {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> canScheduleExactNotifications() async => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> checkPermissionStatus() async => true;

  @override
  Future<bool> requestPermission() async => true;

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

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => [];
}

Future<({JadwalBloc bloc, NotificationCubit cubit})> _bootPage(
  WidgetTester tester, {
  required List<ScheduleItemEntity> items,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final bloc = JadwalBloc(GetJadwal(_JadwalRepoWith(items)));
  bloc.add(const JadwalFetchRequested());

  final cubit = NotificationCubit(
    scheduler: _NoopNotificationScheduler(),
    repository: _NotificationRepoEmpty(),
    notificationService: _NoopNotificationService(),
  );
  addTearDown(() {
    bloc.close();
    cubit.close();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<JadwalBloc>.value(value: bloc),
          BlocProvider<NotificationCubit>.value(value: cubit),
        ],
        child: const JadwalPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (bloc: bloc, cubit: cubit);
}

/// Performs a pull-down gesture and snapshots whether RefreshIndicator's
/// spinner was ever visible during the gesture lifetime.
Future<bool> _probePullToRefresh(
  WidgetTester tester, {
  required String label,
}) async {
  final refreshFinder = find.byType(RefreshIndicator);
  expect(refreshFinder, findsOneWidget);

  const start = Offset(200, 50);
  final gesture = await tester.startGesture(start);
  await tester.pump();

  bool spinnerDuringGesture = false;
  for (var step = 1; step <= 8; step++) {
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 30));
    // RefreshIndicator uses RefreshProgressIndicator internally, not
    // CircularProgressIndicator. Both extend ProgressIndicator but only
    // RefreshProgressIndicator is the one rendered above the scrollable.
    if (find.byType(RefreshProgressIndicator).evaluate().isNotEmpty) {
      spinnerDuringGesture = true;
    }
  }

  await gesture.up();
  await tester.pump(const Duration(milliseconds: 50));

  final spinnerAfterRelease = find
      .byType(RefreshProgressIndicator)
      .evaluate()
      .isNotEmpty;

  debugPrint(
    '[$label] spinner during drag? $spinnerDuringGesture  '
    'after release? $spinnerAfterRelease',
  );
  await tester.pumpAndSettle();
  return spinnerDuringGesture || spinnerAfterRelease;
}

void main() {
  setUp(() {
    try {
      final existing = Services.get<AcademicCacheService>();
      if (existing is! _NoCredsCache) {
        Services.register<AcademicCacheService>(_NoCredsCache());
      }
    } on StateError {
      Services.register<AcademicCacheService>(_NoCredsCache());
    }
  });

  testWidgets('V3-A: empty schedule (pre-fix)', (tester) async {
    await _bootPage(tester, items: const []);
    final works = await _probePullToRefresh(tester, label: 'V3-A empty');
    expect(works, isTrue, reason: 'expected to work; will document actual');
  });

  testWidgets('V3-B: 2 items (pre-fix)', (tester) async {
    await _bootPage(
      tester,
      items: [_mkItem('Senin', 8), _mkItem('Selasa', 10)],
    );
    final works = await _probePullToRefresh(tester, label: 'V3-B 2-items');
    expect(works, isTrue, reason: 'expected to work; will document actual');
  });

  testWidgets('V3-C: 15 items (pre-fix)', (tester) async {
    final items = List.generate(
      15,
      (i) => _mkItem(
        ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'][i % 5],
        8 + (i % 8),
      ),
    );
    await _bootPage(tester, items: items);
    final works = await _probePullToRefresh(tester, label: 'V3-C 15-items');
    expect(works, isTrue, reason: 'expected to work; will document actual');
  });
}
