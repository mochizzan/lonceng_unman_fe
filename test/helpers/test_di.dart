// test/helpers/test_di.dart
/// Shared DI setup for tests that render pages using `Services.get<T>()`.
library;

import 'dart:async';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/features/home/domain/repositories/home_repository.dart';
import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';
import 'package:lonceng_unman_fe/features/profile/domain/repositories/profile_repository.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';

/// Shared ThemeNotifier for tests.
final testThemeNotifier = ThemeNotifier();

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<AuthEntity> login({
    required String npm,
    required String password,
  }) async => AuthEntity(npm: npm, password: password);
}

class _FakeHomeRepo implements HomeRepository {
  @override
  Future<HomeEntity> getHomeData() async => HomeEntity(
    userName: 'Aditya',
    avatarUrl: '',
    nextClass: NextClassEntity(
      courseName: 'Test',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      sks: '3',
    ),
    scheduleItems: const [],
    sksTaken: 20,
    todayClassCount: 2,
    semester: 'Semester 5',
    tahunAjaran: '2025/2026',
    studyProgram: 'Teknik Informatika',
    gpaGanjil: 3.8,
    gpaGenap: 3.9,
  );
}

class _FakeJadwalRepo implements JadwalRepository {
  @override
  Future<JadwalEntity> getJadwal() async => const JadwalEntity(
    selectedDay: 'Senin',
    days: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
    scheduleItems: [],
  );
}

class _FakeProfileRepo implements ProfileRepository {
  @override
  Future<ProfileEntity> getProfile() async => const ProfileEntity(
    userName: 'Test User',
    avatarUrl: '',
    npm: '21081010001',
    studyProgram: 'Teknik Informatika',
    semester: 'Semester 5',
    gpa: 3.8,
    sksTaken: 20,
    sksTotal: 24,
    todayClassCount: 2,
    reminderEnabled: true,
    darkModeEnabled: false,
  );

  @override
  Future<void> refreshFromRemote() async {}
}

class _FakeOnboardingRepository implements OnboardingRepository {
  @override
  bool get isCompleted => true;

  @override
  Future<void> markCompleted() async {}
}

/// Minimal fake for AcademicCacheService used by AuthBloc in tests.
class _FakeAcademicCacheService extends AcademicCacheService {
  final Map<String, String> _creds = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveCredentials({
    required String npm,
    required String password,
  }) async {
    _creds['npm'] = npm;
    _creds['password'] = password;
  }

  @override
  Future<Map<String, String>?> loadCredentials() async {
    if (_creds.isEmpty) return null;
    return Map.from(_creds);
  }

  @override
  Future<void> clearCredentials() async => _creds.clear();

  @override
  bool hasCredentials() => _creds.isNotEmpty;

  @override
  Future<void> saveKrsData({
    required String npm,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<Map<String, dynamic>?> loadKrsData({required String npm}) async =>
      null;

  @override
  bool hasKrsData({required String npm}) => false;

  @override
  Future<void> saveKhsData({
    required String npm,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<Map<String, dynamic>?> loadKhsData({required String npm}) async =>
      null;

  @override
  bool hasKhsData({required String npm}) => false;

  @override
  Future<void> saveKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<Map<String, dynamic>?> loadKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async => null;

  @override
  Future<bool> hasKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async => false;

  @override
  Future<void> saveKhsList({
    required String npm,
    required List<dynamic> data,
  }) async {}

  @override
  Future<List<dynamic>?> loadKhsList({required String npm}) async => null;

  @override
  bool hasKhsList({required String npm}) => false;

  @override
  Future<void> clearKrsData() async {}

  @override
  Future<void> clearKhsData() async {}

  @override
  Future<void> clearAcademicData() async {}

  @override
  Future<void> clearAll() async => _creds.clear();
}

class _FakeDataInitRepo implements DataInitializationRepository {
  @override
  Stream<DataInitStatus> initialize({
    required String npm,
    required String password,
  }) async* {}
}

class _FakeNotificationRepo implements NotificationRepository {
  final List<ScheduledNotificationEntity> _notifications = [];
  int _reminderInterval = 5;

  @override
  Future<List<ScheduledNotificationEntity>> getAll() async =>
      List.unmodifiable(_notifications);

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async => null;

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {
    _notifications.add(notification);
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {
    _notifications.addAll(notifications);
  }

  @override
  Future<void> delete(int id) async {
    _notifications.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> deleteAll() async => _notifications.clear();

  @override
  int getReminderInterval() => _reminderInterval;

  @override
  void setReminderInterval(int minutes) => _reminderInterval = minutes;
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService() : super();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> canScheduleExactNotifications() async => true;

  @override
  Future<bool> requestPermission() async => true;
}

class _FakeNotificationScheduler implements NotificationScheduler {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Register all DI dependencies needed by pages.
/// Call in setUp() or setUpAll() before any widget rendering.
void registerTestDependencies() {
  Services.register<GetAuth>(GetAuth(_FakeAuthRepo()));
  Services.register<GetHome>(GetHome(_FakeHomeRepo()));
  Services.register<GetJadwal>(GetJadwal(_FakeJadwalRepo()));
  Services.register<GetProfile>(GetProfile(_FakeProfileRepo()));
  Services.register<OnboardingRepository>(_FakeOnboardingRepository());
  Services.register<AcademicCacheService>(_FakeAcademicCacheService());
  Services.register<DataInitializationRepository>(_FakeDataInitRepo());
  Services.register<GetDataInitialization>(
    GetDataInitialization(_FakeDataInitRepo()),
  );
  Services.register<NotificationRepository>(_FakeNotificationRepo());
  Services.register<NotificationService>(_FakeNotificationService());
  Services.register<NotificationScheduler>(_FakeNotificationScheduler());
}

/// Unregister all DI dependencies.
/// Call in tearDown() or tearDownAll().
void unregisterTestDependencies() {
  Services.clear();
}
