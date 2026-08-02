// test/main_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/main.dart';

void main() {
  testWidgets('App uses AppRouter.create with injectable router', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoncengUnmanApp());

    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;

    expect(materialApp.routerConfig, isNotNull);
    expect(materialApp.routerConfig, isA<GoRouter>());
  });

  testWidgets('App authenticated user is redirected to home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    await tester.pumpAndSettle();

    // StubAuthStatusProvider returns authenticated, so /login redirects to /home
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Home Page - Countdown & Summary'), findsOneWidget);
  });
}
