// Integration test: unauthenticated user accesses /login.
// Verifies the LoginPage renders when the auth status is unauthenticated
// and the route is wrapped with BlocProvider providing AuthBloc.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';

void main() {
  testWidgets('LoginPage renders on /login for unauthenticated user', (
    tester,
  ) async {
    // Use a custom auth provider that returns unauthenticated.
    final provider = _UnauthenticatedProvider();
    final router = AppRouter.create(
      authStatusProvider: provider,
      initialLocation: '/login',
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    // LoginPage should be visible for unauthenticated user.
    expect(find.text('Masuk ke Akun'), findsOneWidget);
  });
}

class _UnauthenticatedProvider implements AuthStatusProvider {
  @override
  AuthStatus get currentStatus => AuthStatus.unauthenticated;

  @override
  final Stream<AuthStatus> status = const Stream.empty();
}
