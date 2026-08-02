// test/router/app_error_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

void main() {
  testWidgets('AppErrorPage shows 404 message and back button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppErrorPage()));

    expect(find.text('Halaman Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
  });

  testWidgets('AppErrorPage back button navigates to home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppErrorPage(),
        onGenerateRoute: (settings) {
          if (settings.name == '/${RouteNames.home}') {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Home Placeholder')),
            );
          }
          return null;
        },
      ),
    );

    await tester.tap(find.text('Kembali ke Beranda'));
    await tester.pumpAndSettle();

    expect(find.text('Home Placeholder'), findsOneWidget);
  });
}
