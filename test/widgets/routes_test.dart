// Widget tests for the go_router navigation configuration.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/main.dart';

/// Test-only extension that drives the app's global [router] from a
/// [WidgetTester], mirroring the `tester.push(...)` API from the task brief.
extension GoRouterTester on WidgetTester {
  void push(String location) {
    router.go(location);
  }
}

void main() {
  testWidgets('App starts on /login route', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Login Page'), findsOneWidget);
  });

  testWidgets('App has proper theme configuration', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;
    expect(materialApp.theme?.useMaterial3, isTrue);
  });

  testWidgets('Can navigate to home route and see navbar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    tester.push(RouteNames.home);
    await tester.pumpAndSettle();
    expect(find.text('Home Page - Countdown & Summary'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Can navigate to jadwal route', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    tester.push(RouteNames.jadwal);
    await tester.pumpAndSettle();
    expect(find.text('Jadwal Page - Weekly Schedule'), findsOneWidget);
  });

  testWidgets('Can navigate to profile route', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    tester.push(RouteNames.profile);
    await tester.pumpAndSettle();
    expect(find.text('Profile Page - Academic Info'), findsOneWidget);
  });
}
