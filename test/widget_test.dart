// test/widget_test.dart
//
// Widget test for LoncengUnMan app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/main.dart';
import 'helpers/test_di.dart';

void main() {
  setUpAll(registerTestDependencies);
  tearDownAll(unregisterTestDependencies);
  testWidgets('App uses MaterialApp.router for go_router', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      LoncengUnmanApp(
        authStatusNotifier: AuthStatusNotifier(),
        themeNotifier: ThemeNotifier(),
      ),
    );

    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;

    expect(materialApp.routerConfig, isNotNull);
    expect(materialApp.routerConfig, isA<GoRouter>());
  });

  testWidgets('App has proper theme configuration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      LoncengUnmanApp(
        authStatusNotifier: AuthStatusNotifier(),
        themeNotifier: ThemeNotifier(),
      ),
    );

    // Verify the app uses Material 3
    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;
    expect(materialApp.theme?.useMaterial3, isTrue);
  });

  testWidgets('App starts on login for unauthenticated user', (
    WidgetTester tester,
  ) async {
    final notifier = AuthStatusNotifier();
    await tester.pumpWidget(
      LoncengUnmanApp(
        authStatusNotifier: notifier,
        themeNotifier: ThemeNotifier(),
      ),
    );
    await tester.pumpAndSettle();

    // AuthStatusNotifier defaults to unauthenticated, so /login is shown.
    expect(find.text('Masuk Akun'), findsNWidgets(2)); // header + button
  });

  testWidgets('App redirects to home when authenticated', (
    WidgetTester tester,
  ) async {
    final notifier = AuthStatusNotifier();
    notifier.setStatus(AuthStatus.authenticated);
    await tester.pumpWidget(
      LoncengUnmanApp(
        authStatusNotifier: notifier,
        themeNotifier: ThemeNotifier(),
      ),
    );
    // Use pump() instead of pumpAndSettle() because home page has
    // Timer.periodic countdown that never settles.
    await tester.pump();
    await tester.pump();

    // Authenticated user should see the new home page.
    expect(find.text('Halo, Aditya 👋'), findsOneWidget);
  });
}
