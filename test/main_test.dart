// test/main_test.dart
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
  testWidgets('App uses AppRouter.create with injectable router', (
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

  testWidgets('App authenticated user is redirected to home', (
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

    // Authenticated user should see the home page with greeting.
    expect(find.text('Halo, Aditya 👋'), findsOneWidget);
  });
}
