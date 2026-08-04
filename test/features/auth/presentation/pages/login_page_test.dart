import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';

/// Fake [AuthRepository] — completes login only when the test releases it
/// via [completer], so we can assert the loading state.
class FakeAuthRepository implements AuthRepository {
  final Completer<AuthEntity> completer;

  FakeAuthRepository(this.completer);

  @override
  Future<AuthEntity> login({required String npm}) {
    return completer.future;
  }
}

void main() {
  testWidgets('LoginPage renders all DESIGN.md §5.1 elements', (tester) async {
    final completer = Completer<AuthEntity>();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: BlocProvider(
          create: (_) => AuthBloc(
            GetAuth(FakeAuthRepository(completer)),
            AuthStatusNotifier(),
          ),
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.text('Masuk Akun'), findsOneWidget);
    expect(find.text('Gunakan NPM aktif kamu'), findsOneWidget);
    expect(find.text('NPM'), findsOneWidget);
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    expect(find.textContaining('Hubungi Admin'), findsOneWidget);
    expect(find.textContaining('Helpdesk IT'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('submit shows loading when pressed', (tester) async {
    final completer = Completer<AuthEntity>();
    final authStatusNotifier = AuthStatusNotifier();

    final router = GoRouter(
      initialLocation: '/${RouteNames.login}',
      routes: [
        GoRoute(
          path: '/${RouteNames.login}',
          name: RouteNames.login,
          builder: (context, state) => BlocProvider(
            create: (_) => AuthBloc(
              GetAuth(FakeAuthRepository(completer)),
              authStatusNotifier,
            ),
            child: const LoginPage(),
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Release the completer and settle to avoid a hanging bloc.
    completer.complete(
      AuthEntity(
        npm: '21081010001',
        token: 'tok',
        expiresAt: DateTime(2025, 1, 1),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('submit navigates to home after successful login', (
    tester,
  ) async {
    final authStatusNotifier = AuthStatusNotifier();
    final router = AppRouter.create(
      authStatusNotifier: authStatusNotifier,
      initialLocation: '/${RouteNames.login}',
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo Mahasiswa!'), findsOneWidget);

    // Enter valid NPM
    await tester.enterText(find.byKey(const Key('npm_field')), '21081010001');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // After successful login, user should be on home screen
    expect(find.text('Halo Mahasiswa!'), findsNothing);
  });
}
