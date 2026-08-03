// Widget test for Lonceng UnMan app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/main.dart';

void main() {
  testWidgets('App uses MaterialApp.router for go_router', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      LoncengUnmanApp(authStatusNotifier: AuthStatusNotifier()),
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
      LoncengUnmanApp(authStatusNotifier: AuthStatusNotifier()),
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
    await tester.pumpWidget(LoncengUnmanApp(authStatusNotifier: notifier));
    await tester.pumpAndSettle();

    // AuthStatusNotifier defaults to unauthenticated, so /login is shown.
    expect(find.text('Masuk Akun'), findsOneWidget);
  });

  testWidgets('App redirects to home when authenticated', (
    WidgetTester tester,
  ) async {
    final notifier = AuthStatusNotifier();
    notifier.setStatus(AuthStatus.authenticated);
    await tester.pumpWidget(LoncengUnmanApp(authStatusNotifier: notifier));
    await tester.pumpAndSettle();

    // Authenticated user should see the home page.
    expect(find.text('Home Page - Countdown & Summary'), findsOneWidget);
  });
}
