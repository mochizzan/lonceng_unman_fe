import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';

void main() {
  testWidgets('MainShellScaffold renders child and FloatingNavBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: MainShellScaffold(
          currentIndex: 0,
          child: Center(child: Text('Child Content')),
        ),
      ),
    );

    expect(find.text('Child Content'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('FloatingNavBar shows 3 icon buttons: Home, Jadwal, Profile', (
    WidgetTester tester,
  ) async {
    final capturedTaps = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: FloatingNavBar(currentIndex: 0, onTap: capturedTaps.add),
        ),
      ),
    );

    // The new design uses icon-only nav (no text labels).
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    expect(capturedTaps, [1]);
  });
}
