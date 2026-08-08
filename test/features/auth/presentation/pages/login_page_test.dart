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

AuthBloc _makeBloc(GetAuth getAuth) => AuthBloc(
  getAuth,
  saveCredentials: _FakeSaveCredentials(),
  loadCredentials: _FakeLoadCredentials(),
);

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
    expect(find.textContaining('Hubungi Admin'), findsOneWidget);
    expect(find.textContaining('Helpdesk IT'), findsOneWidget);
  });

  testWidgets('submit shows loading when pressed', (tester) async {
    final completer = Completer<AuthEntity>();
    final authStatusNotifier = AuthStatusNotifier();
    final authBloc = _makeBloc(GetAuth(FakeAuthRepository(completer)));

    final router = GoRouter(
      initialLocation: '/${RouteNames.login}',
      routes: [
        GoRoute(
          path: '/${RouteNames.login}',
          name: RouteNames.login,
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: authBloc,
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

    // Release the completer and settle to avoid a hanging bloc.
    completer.complete(AuthEntity(npm: '21081010001', password: 'testpass'));
    await tester.pumpAndSettle();
  });

  testWidgets('submit navigates to home after successful login', (
    tester,
  ) async {
    final authStatusNotifier = AuthStatusNotifier();
    // Use a pre-built authBloc that always succeeds
    final completer = Completer<AuthEntity>();
    completer.complete(AuthEntity(npm: '21081010001', password: 'testpass'));
    final authBloc = _makeBloc(GetAuth(FakeAuthRepository(completer)));

    final router = GoRouter(
      initialLocation: '/${RouteNames.login}',
      routes: [
        GoRoute(
          path: '/${RouteNames.login}',
          name: RouteNames.login,
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: authBloc,
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
    await tester.pumpAndSettle();

    // After successful login, user should be on home screen
    expect(find.text('Halo Mahasiswa!'), findsNothing);
  });
}
