import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/services/pipeline_notification_seeder.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce/hive.dart';

class FakeAcademicCache implements AcademicCacheService {
  Map<String, String>? creds;
  Map<String, dynamic>? krsJson;
  FakeAcademicCache({this.creds, this.krsJson});
  @override
  Future<void> initialize() async {}
  @override
  Future<Map<String, String>?> loadCredentials() async => creds;
  @override
  Future<Map<String, dynamic>?> loadKrsData({required String npm}) async =>
      krsJson;
  @override
  bool hasKrsData({required String npm}) => krsJson != null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeBox extends Fake implements Box<dynamic> {
  final Map<dynamic, dynamic> m = {};
  @override
  dynamic get(dynamic k, {dynamic defaultValue}) =>
      m.containsKey(k) ? m[k] : defaultValue;
  @override
  Future<void> put(dynamic k, dynamic v) async => m[k] = v;
  @override
  Future<int> clear() async {
    final l = m.length;
    m.clear();
    return l;
  }
}

class FakeNLDS extends Fake implements NotificationLocalDataSource {
  final FakeBox box;
  final List<ScheduledNotificationModel> existing;
  FakeNLDS({FakeBox? box, this.existing = const []}) : box = box ?? FakeBox();
  @override
  Box<dynamic> get settingsBox => box as dynamic;
  @override
  List<ScheduledNotificationModel> getAll() => List.from(existing);
}

class FakeScheduler implements NotificationScheduler {
  bool cancelCalled = false;
  List<ScheduleItemEntity>? lastItems;
  int scheduleCalls = 0;
  @override
  Future<void> scheduleAllDays(List<ScheduleItemEntity> items) async {
    scheduleCalls++;
    await cancelAll();
    lastItems = List.from(items);
  }

  @override
  Future<void> cancelAll() async => cancelCalled = true;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeNotifService implements NotificationService {
  final bool grant;
  FakeNotifService({this.grant = true});
  @override
  Future<bool> checkPermissionStatus() async => grant;
  @override
  Future<bool> requestPermission() async => grant;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> canScheduleExactNotifications() async => true;
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required dynamic channel,
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
    required dynamic channel,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
    List<AndroidNotificationAction>? actions,
  }) async {}
  @override
  void setExternalResponseHandler(void Function(NotificationResponse)? h) {}
  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => [];
}

class FakeCubit extends Fake implements NotificationCubit {
  final FakeScheduler scheduler;
  final FakeBox box;
  NotificationState _state = const NotificationState(
    status: NotificationStatus.initial,
    notifications: [],
  );
  bool cancelAllCalled = false;
  FakeCubit({required this.scheduler, required this.box});
  @override
  NotificationState get state => _state;
  @override
  Future<void> scheduleAll(List<ScheduleItemEntity> items) async {
    await scheduler.scheduleAllDays(items);
    _state = NotificationState(
      status: NotificationStatus.loaded,
      notifications: [],
    );
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
    await scheduler.cancelAll();
    await box.put('pipeline_clearedManually', true);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Map<String, dynamic> krsJsonWith(List<Map<String, dynamic>> mkList) => {
  'krs': {
    'mahasiswa': {'nama': 'Test', 'npm': '123', 'program_studi': 'IF'},
    'periode': {'tahun_ajaran': '2024/2025', 'semester': 'Ganjil'},
    'mata_kuliah': mkList,
    'total_sks': mkList.length * 3,
  },
  'metadata': {},
};

Map<String, dynamic> mk({
  required String nama,
  required String hari,
  required String jamMulai,
  required String jamSelesai,
}) => {
  'kode': 'MK001',
  'nama': nama,
  'sks': 3,
  'jadwal': {
    'hari': hari,
    'waktu_mulai': jamMulai,
    'waktu_selesai': jamSelesai,
  },
  'dosen': 'Dr. X',
};

void main() {
  group('PipelineNotificationSeeder S1-S6', () {
    test('S1 - 2 mk success seeds 2 and saves hash', () async {
      final box = FakeBox();
      final scheduler = FakeScheduler();
      final service = FakeNotifService(grant: true);
      final cache = FakeAcademicCache(
        creds: {'npm': '123', 'password': 'p'},
        krsJson: krsJsonWith([
          mk(
            nama: 'Algoritma',
            hari: 'Senin',
            jamMulai: '08:00',
            jamSelesai: '10:00',
          ),
          mk(
            nama: 'Basis Data',
            hari: 'Selasa',
            jamMulai: '13:00',
            jamSelesai: '15:00',
          ),
        ]),
      );
      final nlds = FakeNLDS(box: box);
      final cubit = FakeCubit(scheduler: scheduler, box: box);
      final seeder = PipelineNotificationSeeder(
        cache: cache,
        notifDataSource: nlds,
        cubitProvider: () => cubit as dynamic,
      );
      // Inject scheduler/service via Services would be needed for direct path; we use cubit path so no Services needed
      final r = await seeder.seedFromCache();
      expect(r.kind, SeedResultKind.seeded);
      expect(r.count, 2);
      expect(box.get('pipeline_lastSeedHash'), isNotNull);
      expect(box.get('pipeline_lastSeedHash'), isNot('empty'));
      expect(box.get('pipeline_clearedManually'), false);
      expect(scheduler.lastItems, hasLength(2));
    });

    test('S2 - krs_empty with existing cancels stale', () async {
      final box = FakeBox();
      final scheduler = FakeScheduler();
      final cache = FakeAcademicCache(
        creds: {'npm': '123', 'password': 'p'},
        krsJson: krsJsonWith([]),
      );
      final existing = [
        ScheduledNotificationModel(
          id: 1,
          courseName: 'Old',
          dayOfWeek: 'Senin',
          classTime: DateTime(2026, 1, 1, 8, 0),
          reminderOffset: 5,
          room: 'R1',
          isActive: true,
        ),
      ];
      final nlds = FakeNLDS(box: box, existing: existing);
      final cubit = FakeCubit(scheduler: scheduler, box: box);
      final seeder = PipelineNotificationSeeder(
        cache: cache,
        notifDataSource: nlds,
        cubitProvider: () => cubit as dynamic,
      );
      final r = await seeder.seedFromCache();
      expect(r.kind, SeedResultKind.skipped);
      expect(r.reason, 'krs_empty');
      expect(box.get('pipeline_lastSeedHash'), 'empty');
      expect(cubit.cancelAllCalled, isTrue);
    });

    test('S3 - krs_empty no existing does not cancel', () async {
      final box = FakeBox();
      final scheduler = FakeScheduler();
      final cache = FakeAcademicCache(
        creds: {'npm': '123', 'password': 'p'},
        krsJson: krsJsonWith([]),
      );
      final nlds = FakeNLDS(box: box, existing: []);
      final cubit = FakeCubit(scheduler: scheduler, box: box);
      final seeder = PipelineNotificationSeeder(
        cache: cache,
        notifDataSource: nlds,
        cubitProvider: () => cubit as dynamic,
      );
      final r = await seeder.seedFromCache();
      expect(r.kind, SeedResultKind.skipped);
      expect(r.reason, 'krs_empty');
      expect(cubit.cancelAllCalled, isFalse);
      expect(box.get('pipeline_lastSeedHash'), 'empty');
    });

    test('S4 - cache miss', () async {
      final box = FakeBox();
      final cache = FakeAcademicCache(
        creds: {'npm': '123', 'password': 'p'},
        krsJson: null,
      );
      final nlds = FakeNLDS(box: box, existing: []);
      final scheduler = FakeScheduler();
      final cubit = FakeCubit(scheduler: scheduler, box: box);
      final seeder = PipelineNotificationSeeder(
        cache: cache,
        notifDataSource: nlds,
        cubitProvider: () => cubit as dynamic,
      );
      final r = await seeder.seedFromCache(npm: '123');
      expect(r.kind, SeedResultKind.skipped);
      expect(r.reason, 'krs_cache_miss');
      expect(scheduler.scheduleCalls, 0);
    });

    test('S5 - permission denied via cubit error', () async {
      final box = FakeBox();
      final cache = FakeAcademicCache(
        creds: {'npm': '123', 'password': 'p'},
        krsJson: krsJsonWith([
          mk(
            nama: 'Algoritma',
            hari: 'Senin',
            jamMulai: '08:00',
            jamSelesai: '10:00',
          ),
        ]),
      );
      final nlds = FakeNLDS(box: box);
      // cubit that ends in error state
      final cubit = _ErrorCubit();
      final seeder = PipelineNotificationSeeder(
        cache: cache,
        notifDataSource: nlds,
        cubitProvider: () => cubit,
      );
      final r = await seeder.seedFromCache();
      expect(r.kind, SeedResultKind.failed);
    });

    test('S6 - dedup second call skipped', () async {
      final box = FakeBox();
      final scheduler = FakeScheduler();
      final cache = FakeAcademicCache(
        creds: {'npm': '123', 'password': 'p'},
        krsJson: krsJsonWith([
          mk(
            nama: 'Algoritma',
            hari: 'Senin',
            jamMulai: '08:00',
            jamSelesai: '10:00',
          ),
          mk(
            nama: 'Basis Data',
            hari: 'Selasa',
            jamMulai: '13:00',
            jamSelesai: '15:00',
          ),
        ]),
      );
      final nlds = FakeNLDS(box: box);
      final cubit = FakeCubit(scheduler: scheduler, box: box);
      final seeder = PipelineNotificationSeeder(
        cache: cache,
        notifDataSource: nlds,
        cubitProvider: () => cubit as dynamic,
      );
      final r1 = await seeder.seedFromCache();
      expect(r1.kind, SeedResultKind.seeded);
      final callsAfterFirst = scheduler.scheduleCalls;
      final r2 = await seeder.seedFromCache();
      expect(r2.kind, SeedResultKind.skipped);
      expect(r2.reason, 'dedup');
      expect(scheduler.scheduleCalls, callsAfterFirst);
    });
  });
}

class _ErrorCubit extends Fake implements NotificationCubit {
  @override
  NotificationState get state => const NotificationState(
    status: NotificationStatus.error,
    errorMessage: 'permission_denied',
  );
  @override
  Future<void> scheduleAll(List<ScheduleItemEntity> items) async {}
}
