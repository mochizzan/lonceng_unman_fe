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
    sksTotal: 24,
    todayClassCount: 2,
    semester: 'Semester 5',
    studyProgram: 'Teknik Informatika',
    gpa: 3.8,
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

/// Register all DI dependencies needed by pages.
/// Call in setUp() or setUpAll() before any widget rendering.
void registerTestDependencies() {
  Services.register<GetAuth>(GetAuth(_FakeAuthRepo()));
  Services.register<GetHome>(GetHome(_FakeHomeRepo()));
  Services.register<GetJadwal>(GetJadwal(_FakeJadwalRepo()));
  Services.register<GetProfile>(GetProfile(_FakeProfileRepo()));
}

/// Unregister all DI dependencies.
/// Call in tearDown() or tearDownAll().
void unregisterTestDependencies() {
  Services.clear();
}
