// Integration test: unauthenticated user accesses /login.
// Verifies the LoginPage renders when the auth status is unauthenticated
// and the route is wrapped with BlocProvider providing AuthBloc.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';

void main() {
  testWidgets('LoginPage renders on /login for unauthenticated user', (
    tester,
  ) async {
    final notifier = AuthStatusNotifier();
    final router = AppRouter.create(
      authStatusNotifier: notifier,
      initialLocation: '/login',
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    // LoginPage should be visible for unauthenticated user.
    expect(find.text('Masuk Akun'), findsOneWidget);
  });
}
