// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

/// Hand-written [ConnectivityService] fake — required because
/// [DataInitBloc] now resolves [ConnectivityService] in its constructor
/// to support the offline fail-fast path.
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

/// Fake [AuthRepository] — completes login only when the test releases it
/// via [completer], so we can assert the loading state.
class FakeAuthRepository implements AuthRepository {
  final Completer<AuthEntity> completer;

  FakeAuthRepository(this.completer);

  @override
  Future<AuthEntity> login({required String npm, required String password}) {
    return completer.future;
  }
}

/// No-op credential services for tests.
class _FakeSaveCredentials implements SaveAuthCredentials {
  @override
  Future<void> call({required String npm, required String password}) async {}
}

class _FakeLoadCredentials implements LoadAuthCredentials {
  @override
  Future<Map<String, String>?> call() async => null;
}

/// Fake in-memory untuk StudentProfileCacheService — tanpa Hive.
class _FakeStudentProfileCacheService extends StudentProfileCacheService {
  final Map<String, Map<String, dynamic>> _cache = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveProfile({
    required String npm,
    required Map<String, dynamic> profileData,
  }) async {
    _cache[npm] = profileData;
  }

  @override
  Future<Map<String, dynamic>?> loadProfile({required String npm}) async {
    return _cache[npm];
  }

  @override
  bool hasProfile({required String npm}) => _cache.containsKey(npm);

  @override
  Future<void> clearProfile({required String npm}) async {
    _cache.remove(npm);
  }

  @override
  Future<void> clearAll() async => _cache.clear();
}

/// Fake StudentProfileRemoteDataSource — return model kosong.
class _FakeStudentProfileRemoteDataSource
    implements StudentProfileRemoteDataSource {
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

/// Fake AcademicCacheService — no-op for tests.
class _FakeAcademicCacheService implements AcademicCacheService {
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
  Future<void> saveIsAlumni({
    required String npm,
    required bool isAlumni,
  }) async {}
  @override
  Future<bool> loadIsAlumni({required String npm}) async => false;
  @override
  Future<void> clearKrsDataFor({required String npm}) async {}
  @override
  Future<void> clearKrsData() async {}
  @override
  Future<void> clearKhsData() async {}
  @override
  Future<void> clearAcademicData() async {}
  @override
  Future<void> clearAll() async {}
}

AuthBloc _makeBloc(GetAuth getAuth) => AuthBloc(
  getAuth,
  saveCredentials: _FakeSaveCredentials(),
  loadCredentials: _FakeLoadCredentials(),
  profileDataSource: _FakeStudentProfileRemoteDataSource(),
  profileCacheService: _FakeStudentProfileCacheService(),
  academicCacheService: _FakeAcademicCacheService(),
);

/// Repositori data-init palsu yang tidak pernah memancarkan progres.
/// LoginPage memicu pipeline lewat BlocListener setelah login sukses, jadi
/// DataInitBloc wajib tersedia; stream kosong menjaga UI berhenti di
/// keadaan "sedang menyiapkan data" tanpa kerja jaringan apa pun.
class _FakeDataInitRepository implements DataInitializationRepository {
  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) async* {
    // Emit at least one progress event so DataInitProgressView shows
    // CircularProgressIndicator (it hides on DataInitSuccess/Failure).
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    yield const DataInitProgress(DataInitStatus.completed);
  }

  @override
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  }) async* {
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    yield const DataInitProgress(DataInitStatus.completed);
  }
}

DataInitBloc _makeDataInitBloc() => DataInitBloc(
  GetDataInitialization(_FakeDataInitRepository()),
  connectivity: _FakeConnectivityService(isOnline: true),
);

/// Kartu login berada di bawah lipatan pada viewport uji baku 800x600,
/// sehingga tap() meleset ke luar batas render tree. Perbesar permukaan uji
/// agar seluruh formulir benar-benar dapat ditekan seperti pada perangkat.
Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('LoginPage renders all DESIGN.md §5.1 elements', (tester) async {
    final authNotifier = AuthStatusNotifier();
    final completer = Completer<AuthEntity>();
    final authBloc = _makeBloc(GetAuth(FakeAuthRepository(completer)));
    final connectivityCubit = ConnectivityCubit(
      _FakeConnectivityService(isOnline: true),
    );
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.text('Masuk Akun'), findsNWidgets(2)); // header + button
    expect(find.text('Gunakan NPM aktif kamu'), findsOneWidget);
    expect(find.text('NPM'), findsOneWidget);
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.textContaining('Butuh bantuan?'), findsOneWidget);
    expect(find.textContaining('Helpdesk IT'), findsOneWidget);

    unawaited(connectivityCubit.close());
  });

  testWidgets('submit shows loading when pressed', (tester) async {
    final completer = Completer<AuthEntity>();
    final authStatusNotifier = AuthStatusNotifier();
    final authBloc = _makeBloc(GetAuth(FakeAuthRepository(completer)));
    final connectivityCubit = ConnectivityCubit(
      _FakeConnectivityService(isOnline: true),
    );
    await _useTallSurface(tester);

    final router = GoRouter(
      initialLocation: '/${RouteNames.login}',
      routes: [
        GoRoute(
          path: '/${RouteNames.login}',
          name: RouteNames.login,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<DataInitBloc>(create: (_) => _makeDataInitBloc()),
            ],
            child: LoginPage(authStatusNotifier: authStatusNotifier),
          ),
        ),
        GoRoute(
          path: '/${RouteNames.home}',
          name: RouteNames.home,
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: lightTheme, routerConfig: router),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Enter a valid 11-digit NPM
    await tester.enterText(find.byKey(const Key('npm_field')), '21081010001');
    // Enter password
    await tester.enterText(find.byKey(const Key('password_field')), 'testpass');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Masuk Akun').last);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Lepaskan completer. Setelah login sukses UI berpindah ke progress yang
    // memuat CircularProgressIndicator berputar, jadi pumpAndSettle akan
    // menggantung selamanya — gunakan pump bertahap.
    completer.complete(AuthEntity(npm: '21081010001', password: 'testpass'));
    await tester.pump();
    await tester.pump();

    unawaited(connectivityCubit.close());
  });

  testWidgets('submit navigates to home after successful login', (
    tester,
  ) async {
    final authStatusNotifier = AuthStatusNotifier();
    // Use a pre-built authBloc that always succeeds
    final completer = Completer<AuthEntity>();
    completer.complete(AuthEntity(npm: '21081010001', password: 'testpass'));
    final authBloc = _makeBloc(GetAuth(FakeAuthRepository(completer)));
    final connectivityCubit = ConnectivityCubit(
      _FakeConnectivityService(isOnline: true),
    );
    await _useTallSurface(tester);

    final router = GoRouter(
      initialLocation: '/${RouteNames.login}',
      routes: [
        GoRoute(
          path: '/${RouteNames.login}',
          name: RouteNames.login,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<DataInitBloc>(create: (_) => _makeDataInitBloc()),
            ],
            child: LoginPage(authStatusNotifier: authStatusNotifier),
          ),
        ),
        GoRoute(
          path: '/${RouteNames.home}',
          name: RouteNames.home,
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: lightTheme, routerConfig: router),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Halo Mahasiswa!'), findsOneWidget);

    // Enter valid NPM and password
    await tester.enterText(find.byKey(const Key('npm_field')), '21081010001');
    await tester.enterText(find.byKey(const Key('password_field')), 'testpass');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Masuk Akun').last);
    // Profile scrape succeeds → AuthProfileReview → ReviewScreen appears.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Confirm profile to proceed to AuthAuthenticated + DataInitProgressView.
    expect(find.text('Ya, Konfirmasi'), findsOneWidget);
    await tester.tap(find.text('Ya, Konfirmasi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // After confirmation, DataInitProgressView shows completion state
    // ("Data akademik siap") — login form no longer visible.
    expect(find.text('Data akademik siap'), findsOneWidget);

    // Allow DataInitProgressView's delayed onComplete (500ms) to fire
    await tester.pump(const Duration(milliseconds: 600));
    // Dispose tree to cancel any remaining timers
    await tester.pumpWidget(Container());
    await tester.pump();
    unawaited(connectivityCubit.close());
  });
}
