// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/core/utils/offline_sheet_controller.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

class _NoopAuthRepo implements AuthRepository {
  @override
  Future<AuthEntity> login({
    required String npm,
    required String password,
  }) async => AuthEntity(npm: npm, password: password);
}

class _NoopSave implements SaveAuthCredentials {
  @override
  Future<void> call({required String npm, required String password}) async {}
}

class _NoopLoad implements LoadAuthCredentials {
  @override
  Future<Map<String, String>?> call() async => null;
}

class _NoopProfileDS implements StudentProfileRemoteDataSource {
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
  }) async => const StudentProfileModel(
    nim: '',
    nisn: '',
    nik: '',
    namaMahasiswa: 'X',
    programStudi: 'SI',
    semester: 'GANJIL',
    kelas: 'A',
    statusKonversi: '2022',
  );
  @override
  Future<StudentProfileModel> getProfilePreview({
    required String npm,
    required String password,
  }) async => const StudentProfileModel(
    nim: '',
    nisn: '',
    nik: '',
    namaMahasiswa: 'X',
    programStudi: 'SI',
    semester: 'GANJIL',
    kelas: 'A',
    statusKonversi: '2022',
  );
}

class _NoopAcademic extends AcademicCacheService {
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

class _NoopProfileCache extends StudentProfileCacheService {
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

class _FakeConn implements ConnectivityService {
  _FakeConn({bool isOnline = true}) : _isOnline = isOnline;
  bool _isOnline;
  final _c = StreamController<bool>.broadcast();
  @override
  bool get isOnline => _isOnline;
  @override
  Stream<bool> get onStatusChange => _c.stream;
  @override
  Future<void> refresh() async {}
  void setOnline(bool v) {
    _isOnline = v;
    _c.add(v);
  }
}

void main() {
  setUp(() {
    Services.clear();
    Services.register<OfflineSheetController>(OfflineSheetController());
  });
  tearDown(() => Services.clear());

  testWidgets('header texts are center-aligned', (tester) async {
    final fakeConn = _FakeConn(isOnline: true);
    final cubit = ConnectivityCubit(fakeConn);
    final authBloc = AuthBloc(
      GetAuth(_NoopAuthRepo()),
      saveCredentials: _NoopSave(),
      loadCredentials: _NoopLoad(),
      profileDataSource: _NoopProfileDS(),
      profileCacheService: _NoopProfileCache(),
      academicCacheService: _NoopAcademic(),
    );
    final notifier = AuthStatusNotifier();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ConnectivityCubit>.value(value: cubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: LoginPage(authStatusNotifier: notifier),
        ),
      ),
    );
    // pump to settle AnimatedSwitcher (300ms) without waiting for infinite tickers
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final titleFinder = find.text(AppStrings.loginButton);
    expect(titleFinder, findsWidgets);
    final texts = tester.widgetList<Text>(titleFinder).toList();
    final hasCenterHeader = texts.any((t) => t.textAlign == TextAlign.center);
    expect(
      hasCenterHeader,
      isTrue,
      reason: 'Masuk Akun header must be TextAlign.center',
    );

    final helper = tester.widget<Text>(find.text(AppStrings.loginNpmHelper));
    expect(helper.textAlign, TextAlign.center);

    // Close without hanging — broadcast controller cancel may stall if pump still active
    unawaited(cubit.close());
    unawaited(authBloc.close());
    notifier.dispose();
  });
}
