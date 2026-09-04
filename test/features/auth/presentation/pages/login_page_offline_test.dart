// Widget tests for [LoginPage]'s offline banner.
//
// The banner appears inside the LoginPage when [ConnectivityCubit] reports
// isOnline == false. We inject a hand-written [ConnectivityService] fake
// and toggle its state from the test driver.
//
// Hand-written fakes only — no mockito, no mocktail, no codegen.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

/// No-op [AuthRepository] — never invoked because no test presses submit.
class _NoopAuthRepo implements AuthRepository {
  @override
  Future<AuthEntity> login({
    required String npm,
    required String password,
  }) async {
    return AuthEntity(npm: npm, password: password);
  }
}

class _NoopSaveCredentials implements SaveAuthCredentials {
  @override
  Future<void> call({required String npm, required String password}) async {}
}

class _NoopLoadCredentials implements LoadAuthCredentials {
  @override
  Future<Map<String, String>?> call() async => null;
}

class _NoopStudentProfileRemoteDS implements StudentProfileRemoteDataSource {
  @override
  Future<void> scrapeProfile({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {}

  @override
  Future<StudentProfileModel> getProfile({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    return const StudentProfileModel(
      nim: '',
      nisn: '',
      nik: '',
      namaMahasiswa: 'Test User',
      programStudi: 'SI',
      semester: 'GANJIL',
      kelas: 'Teknik',
      statusKonversi: '2022',
    );
  }

  @override
  Future<StudentProfileModel> getProfilePreview({
    required String npm,
    required String password,
  }) async {
    return const StudentProfileModel(
      nim: '',
      nisn: '',
      nik: '',
      namaMahasiswa: 'Test User',
      programStudi: 'SI',
      semester: 'GANJIL',
      kelas: 'Teknik',
      statusKonversi: '2022',
    );
  }
}

class _NoopStudentProfileCache extends StudentProfileCacheService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> saveProfile({
    required String npm,
    required Map<String, dynamic> profileData,
  }) async {}
  @override
  Future<Map<String, dynamic>?> loadProfile({required String npm}) async =>
      null;
  @override
  bool hasProfile({required String npm}) => false;
  @override
  Future<void> clearProfile({required String npm}) async {}
  @override
  Future<void> clearAll() async {}
}

class _NoopAcademicCache implements AcademicCacheService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> saveCredentials({
    required String npm,
    required String password,
  }) async {}
  @override
  Future<Map<String, String>?> loadCredentials() async => null;
  @override
  Future<Map<String, String>?> loadCredentialsByNpm(String npm) async => null;
  @override
  bool hasCredentials() => false;
  @override
  Future<void> clearCredentials() async {}
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
  Future<void> saveKhsList({
    required String npm,
    required List<dynamic> data,
  }) async {}
  @override
  Future<List<dynamic>?> loadKhsList({required String npm}) async => null;
  @override
  bool hasKhsList({required String npm}) => false;
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
  bool hasAcademicData({required String npm}) => false;
  @override
  Future<void> clearKrsData() async {}
  @override
  Future<void> clearKhsData() async {}
  @override
  Future<void> clearAcademicData() async {}
  @override
  Future<void> clearAll() async {}
}

/// Hand-written [ConnectivityService] fake. Tests drive it via [setOnline].
class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({bool isOnline = true}) : _isOnline = isOnline;

  bool _isOnline;
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  @override
  Future<void> refresh() async {}

  void setOnline(bool v) {
    _isOnline = v;
    _controller.add(v);
  }
}

void main() {
  testWidgets('offline banner is NOT visible when online', (tester) async {
    final fakeConn = _FakeConnectivityService(isOnline: true);
    final connectivityCubit = ConnectivityCubit(fakeConn);
    final authBloc = AuthBloc(
      GetAuth(_NoopAuthRepo()),
      saveCredentials: _NoopSaveCredentials(),
      loadCredentials: _NoopLoadCredentials(),
      profileDataSource: _NoopStudentProfileRemoteDS(),
      profileCacheService: _NoopStudentProfileCache(),
      academicCacheService: _NoopAcademicCache(),
    );
    final authNotifier = AuthStatusNotifier();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: LoginPage(authStatusNotifier: authNotifier),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.loginOfflineBanner), findsNothing);

    await connectivityCubit.close();
    await authBloc.close();
    authNotifier.dispose();
  });

  testWidgets('offline banner appears when connectivity flips to offline', (
    tester,
  ) async {
    final fakeConn = _FakeConnectivityService(isOnline: true);
    final connectivityCubit = ConnectivityCubit(fakeConn);
    final authBloc = AuthBloc(
      GetAuth(_NoopAuthRepo()),
      saveCredentials: _NoopSaveCredentials(),
      loadCredentials: _NoopLoadCredentials(),
      profileDataSource: _NoopStudentProfileRemoteDS(),
      profileCacheService: _NoopStudentProfileCache(),
      academicCacheService: _NoopAcademicCache(),
    );
    final authNotifier = AuthStatusNotifier();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: LoginPage(authStatusNotifier: authNotifier),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.loginOfflineBanner), findsNothing);

    fakeConn.setOnline(false);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loginOfflineBanner), findsOneWidget);

    await connectivityCubit.close();
    await authBloc.close();
    authNotifier.dispose();
  });
}
