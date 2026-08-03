// test/features/settings/presentation/pages/settings_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('SettingsPage renders appBar with title and settings items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Tema Aplikasi'), findsOneWidget);
    expect(find.text('Ingatkan Sebelum Kelas'), findsOneWidget);
    expect(find.text('Versi Aplikasi'), findsOneWidget);
  });
}
