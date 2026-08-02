// test/router/main_shell_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';

void main() {
  testWidgets('MainShellScaffold renders child and FloatingNavBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainShellScaffold(
          currentIndex: 0,
          child: Center(child: Text('Child Content')),
        ),
      ),
    );

    expect(find.text('Child Content'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('FloatingNavBar shows 3 items: Home, Jadwal, Profile', (
    WidgetTester tester,
  ) async {
    final capturedTaps = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingNavBar(currentIndex: 0, onTap: capturedTaps.add),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Jadwal'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Jadwal'));
    expect(capturedTaps, [1]);
  });
}
