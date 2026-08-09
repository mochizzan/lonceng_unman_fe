import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

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
}

AuthBloc _makeBloc(GetAuth getAuth) => AuthBloc(
  getAuth,
  saveCredentials: _FakeSaveCredentials(),
  loadCredentials: _FakeLoadCredentials(),
  profileDataSource: _FakeStudentProfileRemoteDataSource(),
  profileCacheService: _FakeStudentProfileCacheService(),
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
  }) => const Stream<DataInitProgress>.empty();
}

DataInitBloc _makeDataInitBloc() =>
    DataInitBloc(GetDataInitialization(_FakeDataInitRepository()));

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
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: LoginPage(authStatusNotifier: authNotifier),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.text('Masuk Akun'), findsNWidgets(2)); // header + button
    expect(find.text('Gunakan NPM aktif kamu'), findsOneWidget);
    expect(find.text('NPM'), findsOneWidget);
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.textContaining('Butuh bantuan?'), findsOneWidget);
    expect(find.textContaining('Helpdesk IT'), findsOneWidget);
  });

  testWidgets('submit shows loading when pressed', (tester) async {
    final completer = Completer<AuthEntity>();
    final authStatusNotifier = AuthStatusNotifier();
    final authBloc = _makeBloc(GetAuth(FakeAuthRepository(completer)));
    await _useTallSurface(tester);

    final router = GoRouter(
      initialLocation: '/${RouteNames.login}',
      routes: [
        GoRoute(
          path: '/${RouteNames.login}',
          name: RouteNames.login,
          builder: (context, state) => MultiBlocProvider(
            providers: [
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
    await tester.pumpAndSettle();

    // Enter a valid 11-digit NPM
    await tester.enterText(find.byKey(const Key('npm_field')), '21081010001');
    // Enter password
    await tester.enterText(find.byKey(const Key('password_field')), 'testpass');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk Akun').last);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Lepaskan completer. Setelah login sukses UI berpindah ke progress yang
    // memuat CircularProgressIndicator berputar, jadi pumpAndSettle akan
    // menggantung selamanya — gunakan pump bertahap.
    completer.complete(AuthEntity(npm: '21081010001', password: 'testpass'));
    await tester.pump();
    await tester.pump();
  });

  testWidgets('submit navigates to home after successful login', (
    tester,
  ) async {
    final authStatusNotifier = AuthStatusNotifier();
    // Use a pre-built authBloc that always succeeds
    final completer = Completer<AuthEntity>();
    completer.complete(AuthEntity(npm: '21081010001', password: 'testpass'));
    final authBloc = _makeBloc(GetAuth(FakeAuthRepository(completer)));
    await _useTallSurface(tester);

    final router = GoRouter(
      initialLocation: '/${RouteNames.login}',
      routes: [
        GoRoute(
          path: '/${RouteNames.login}',
          name: RouteNames.login,
          builder: (context, state) => MultiBlocProvider(
            providers: [
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
    await tester.pumpAndSettle();

    expect(find.text('Halo Mahasiswa!'), findsOneWidget);

    // Enter valid NPM and password
    await tester.enterText(find.byKey(const Key('npm_field')), '21081010001');
    await tester.enterText(find.byKey(const Key('password_field')), 'testpass');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk Akun').last);
    // Progress UI menampilkan indikator berputar; pumpAndSettle akan
    // menggantung, jadi pompa beberapa frame saja.
    await tester.pump();
    await tester.pump();

    // After successful login, user should be on home screen
    expect(find.text('Halo Mahasiswa!'), findsNothing);
  });
}
