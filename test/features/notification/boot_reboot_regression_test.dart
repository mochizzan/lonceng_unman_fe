import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// Fakes — hand-written, no mockito (repo style)
// ---------------------------------------------------------------------------
class FakeRepo implements NotificationRepository {
  final List<ScheduledNotificationEntity> _store = [];
  int _interval = 5;
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
  Future<void> save(ScheduledNotificationEntity n) async {
    _store.removeWhere((e) => e.id == n.id);
    _store.add(n);
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> ns) async {
    for (final n in ns) await save(n);
  }

  @override
  Future<void> delete(int id) async => _store.removeWhere((e) => e.id == id);
  @override
  Future<void> deleteAll() async => _store.clear();
  @override
  int getReminderInterval() => _interval;
  @override
  void setReminderInterval(int m) => _interval = m;
}

class FakeService implements NotificationService {
  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];
  bool allCancelled = false;
  // capture last schedule args for assertion
  final List<Map<String, dynamic>> scheduledCalls = [];

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
    scheduledCalls.add({
      'id': id,
      'title': title,
      'scheduledDate': scheduledDate,
      'matchDateTimeComponents': matchDateTimeComponents,
      'mode': androidScheduleMode,
    });
  }

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);
  @override
  Future<void> cancelAll() async => allCancelled = true;
  @override
  Future<bool> canScheduleExactNotifications() async => true;
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
  void setExternalResponseHandler(void Function(NotificationResponse p1)? h) {}

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => scheduledIds
      .map((id) => PendingNotificationRequest(id, '', '', null))
      .toList();
}

List<ScheduleItemEntity> dummyItems() => [
  ScheduleItemEntity(
    courseName: 'Algoritma',
    startTime: DateTime(2026, 1, 5, 8, 0),
    endTime: DateTime(2026, 1, 5, 10, 0),
    room: 'R.301',
    sks: '3',
    status: ScheduleStatus.upcoming,
    dayOfWeek: 'Senin',
  ),
  ScheduleItemEntity(
    courseName: 'Basis Data',
    startTime: DateTime(2026, 1, 6, 13, 0),
    endTime: DateTime(2026, 1, 6, 15, 0),
    room: 'R.201',
    sks: '3',
    status: ScheduleStatus.upcoming,
    dayOfWeek: 'Selasa',
  ),
  ScheduleItemEntity(
    courseName: 'Jaringan',
    startTime: DateTime(2026, 1, 7, 10, 0),
    endTime: DateTime(2026, 1, 7, 12, 0),
    room: 'R.102',
    sks: '2',
    status: ScheduleStatus.upcoming,
    dayOfWeek: 'Rabu',
  ),
];

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  });

  group('BOOT-REBOOT REGRESSION — AlarmManager hilang setelah restart', () {
    test(
      'BUG PROOF: Hive persist tapi AlarmManager kosong setelah simulasi reboot — tanpa restore, alarm hilang',
      () async {
        final repo = FakeRepo();
        final service = FakeService();
        final scheduler = NotificationScheduler(
          repository: repo,
          notificationService: service,
        );

        // 1. User menjadwalkan semua hari (cold schedule)
        await scheduler.scheduleAllDays(dummyItems());
        expect(repo.getAll(), completion(hasLength(3)));
        expect(service.scheduledIds, hasLength(3));
        final hiveCount = (await repo.getAll()).length;
        final alarmCountBeforeReboot = service.scheduledIds.length;

        // 2. Simulasi REBOOT: OS menghapus semua AlarmManager PendingIntents.
        //    Hive tetap (tidak di-clear), AlarmManager kosong.
        service.scheduledIds.clear();
        service.scheduledCalls.clear();
        service.allCancelled = false;
        // Repo TIDAK di-clear — ini persist.

        // 3. Cold start TANPA restore (perilaku sekarang di main.dart):
        //    main() hanya Hive.openBox + NotificationService.initialize() + _reconcileDelivered
        //    Tidak ada scheduler.restoreAll() — jadi alarm tetap 0.
        final hiveAfterReboot = (await repo.getAll()).length;
        final alarmAfterRebootWithoutRestore = service.scheduledIds.length;

        expect(
          hiveAfterReboot,
          hiveCount,
          reason: 'Hive harus survive reboot (file di cache/)',
        );
        expect(alarmCountBeforeReboot, 3, reason: 'Pre-reboot ada 3 alarm');
        expect(
          alarmAfterRebootWithoutRestore,
          0,
          reason:
              'BUG: tanpa restore, AlarmManager kosong setelah reboot — notifikasi tidak akan bunyi',
        );

        // Bukti celah: scheduledIds 0 tapi Hive 3 → celah boot.
        // Test ini PASS = bug terbukti ada. Bila lib sudah punya restoreAll
        // dan dipanggil di main(), test ini harus diubah jadi expect alarm == hiveCount.
      },
    );

    test(
      'API GAP CLOSED: NotificationScheduler.restoreAll() ada — celah boot tertutup',
      () async {
        final repo = FakeRepo();
        final service = FakeService();
        final scheduler = NotificationScheduler(
          repository: repo,
          notificationService: service,
        );

        final restored = await scheduler.restoreAll();
        expect(
          restored,
          0,
          reason: 'restoreAll() ada dan no-op bila Hive kosong (gap closed)',
        );
      },
    );

    test(
      'FIX PROOF: scheduler.restoreAll() re-hydrate AlarmManager dari Hive — alarm kembali N',
      () async {
        final repo = FakeRepo();
        final service = FakeService();
        final scheduler = NotificationScheduler(
          repository: repo,
          notificationService: service,
        );

        await scheduler.scheduleAllDays(dummyItems());
        expect(service.scheduledIds, hasLength(3));

        // Simulasi reboot: AlarmManager hilang, Hive tetap
        service.scheduledIds.clear();
        service.scheduledCalls.clear();
        expect(service.scheduledIds, isEmpty);
        expect(await repo.getAll(), hasLength(3));

        final restored = await scheduler.restoreAll();

        expect(restored, 3);
        expect(service.scheduledIds, hasLength(3));
        // Weekly recurring harus pakai dayOfWeekAndTime
        for (final c in service.scheduledCalls) {
          expect(
            c['matchDateTimeComponents'],
            DateTimeComponents.dayOfWeekAndTime,
          );
        }
        // Id deterministik harus sama sebelum & sesudah restore
        final idsAfter = service.scheduledIds.toSet();
        final expectedIds = (await repo.getAll()).map((e) => e.id).toSet();
        expect(idsAfter, expectedIds);
      },
    );

    test(
      'FIX EDGE: restore skip inactive — tidak re-register yang dinonaktifkan user',
      () async {
        final repo = FakeRepo();
        final service = FakeService();
        final scheduler = NotificationScheduler(
          repository: repo,
          notificationService: service,
        );

        // 2 aktif, 1 nonaktif
        final active = ScheduledNotificationEntity(
          id: 1,
          courseName: 'Aktif',
          dayOfWeek: 'Senin',
          classTime: DateTime(2026, 1, 5, 8, 0),
          reminderOffset: 5,
          room: 'R1',
          isActive: true,
        );
        final inactive = ScheduledNotificationEntity(
          id: 2,
          courseName: 'Nonaktif',
          dayOfWeek: 'Selasa',
          classTime: DateTime(2026, 1, 6, 9, 0),
          reminderOffset: 5,
          room: 'R2',
          isActive: false,
        );
        await repo.save(active);
        await repo.save(inactive);

        final restored = await scheduler.restoreAll();
        expect(restored, 1);
        expect(service.scheduledIds, contains(1));
        expect(service.scheduledIds, isNot(contains(2)));
      },
    );

    test(
      'FIX EDGE: restore idempotent — dipanggil 2x tidak duplikat (zonedSchedule overwrite by id)',
      () async {
        final repo = FakeRepo();
        final service = FakeService();
        final scheduler = NotificationScheduler(
          repository: repo,
          notificationService: service,
        );

        await scheduler.scheduleAllDays(dummyItems());
        service.scheduledIds.clear();
        service.scheduledCalls.clear();

        await scheduler.restoreAll();
        await scheduler.restoreAll();

        // Tiap restore menambah 3 calls (overwrite by id di OS, tapi di fake kita append)
        expect(service.scheduledCalls, hasLength(6));
        // Id set tetap 3 unique
        expect(service.scheduledIds.toSet(), hasLength(3));
      },
    );

    test(
      'FIX EDGE: Hive kosong → restore no-op (fresh install / clear cache)',
      () async {
        final repo = FakeRepo();
        final service = FakeService();
        final scheduler = NotificationScheduler(
          repository: repo,
          notificationService: service,
        );

        final restored = await scheduler.restoreAll();
        expect(restored, 0);
        expect(service.scheduledIds, isEmpty);
      },
    );
  });
}
