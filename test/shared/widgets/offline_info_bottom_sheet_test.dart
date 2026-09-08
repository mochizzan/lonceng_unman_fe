import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/shared/widgets/offline_info_bottom_sheet.dart';

void main() {
  testWidgets('renders icon, title, desc, and Mengerti button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OfflineInfoBottomSheet())),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text(AppStrings.loginOfflineSheetTitle), findsOneWidget);
    expect(find.text(AppStrings.loginOfflineBanner), findsOneWidget);
    expect(
      find.byKey(const Key('offline_sheet_understood_button')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.loginOfflineSheetAction), findsOneWidget);
  });

  testWidgets('onUnderstood callback invoked on Mengerti tap', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineInfoBottomSheet(onUnderstood: () => called = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('offline_sheet_understood_button')));
    await tester.pumpAndSettle();
    expect(called, isTrue);
  });

  testWidgets(
    'showOfflineInfoBottomSheet helper shows modal and Mengerti dismisses',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showOfflineInfoBottomSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginOfflineSheetTitle), findsOneWidget);
      expect(
        find.byKey(const Key('offline_sheet_understood_button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('offline_sheet_understood_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginOfflineSheetTitle), findsNothing);
    },
  );
}
