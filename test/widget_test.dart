// Widget test for Lonceng UnMan app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/main.dart';

void main() {
  testWidgets('App starts and shows login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LoncengUnmanApp());

    // Verify login page is shown (initial route is /login)
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('App has proper theme configuration', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());

    // Verify the app uses Material 3
    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;
    expect(materialApp.theme?.useMaterial3, isTrue);
  });
}
