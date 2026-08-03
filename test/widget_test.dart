// Widget test for Lonceng UnMan app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/main.dart';

void main() {
  testWidgets('App starts and shows home page after auth redirect', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LoncengUnmanApp());
    await tester.pumpAndSettle();

    // StubAuthStatusProvider returns authenticated, so /login redirects to /home
    expect(find.text('Home Page - Countdown & Summary'), findsOneWidget);
  });

  testWidgets('App has proper theme configuration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoncengUnmanApp());

    // Verify the app uses Material 3
    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;
    expect(materialApp.theme?.useMaterial3, isTrue);
  });

  testWidgets('App uses MaterialApp.router for go_router', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;

    expect(materialApp.routerConfig, isNotNull);
    expect(materialApp.routerConfig, isA<GoRouter>());
  });
}
