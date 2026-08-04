import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_button.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

void main() {
  testWidgets('AppButton renders FilledButton', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: AppButton(onPressed: () {}, child: const Text('Masuk')),
        ),
      ),
    );
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('AppTextField renders with label and icon', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'NPM',
            icon: Icons.badge_outlined,
          ),
        ),
      ),
    );
    expect(find.text('NPM'), findsOneWidget);
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
  });

  testWidgets('AuthBackground renders child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: AuthBackground(child: Text('Content'))),
      ),
    );
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('BellLogo renders toga cap icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: BellLogo()),
      ),
    );
    expect(find.byIcon(Icons.school), findsOneWidget);
  });
}
