import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/utils/offline_sheet_controller.dart';

void main() {
  testWidgets('sync shows sheet when offline + isLoginForm', (tester) async {
    final controller = OfflineSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () {}, child: const Text('x')),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.text('x'));

    controller.sync(false, ctx, isLoginForm: true);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);

    // Dismiss for cleanup
    controller.dismissIfShowing(ctx);
    await tester.pumpAndSettle();
  });

  testWidgets('sync guard prevents double show', (tester) async {
    final controller = OfflineSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(body: Center(child: Text('x'))),
        ),
      ),
    );
    final ctx = tester.element(find.text('x'));

    controller.sync(false, ctx, isLoginForm: true);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);

    controller.sync(false, ctx, isLoginForm: true);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);

    controller.dismissIfShowing(ctx);
    await tester.pumpAndSettle();
  });

  testWidgets('sync online without showing is no-op', (tester) async {
    final controller = OfflineSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('x'))),
      ),
    );
    final ctx = tester.element(find.text('x'));

    controller.sync(true, ctx, isLoginForm: true);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isFalse);
  });

  testWidgets('sync offline with isLoginForm false does not show', (
    tester,
  ) async {
    final controller = OfflineSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('x'))),
      ),
    );
    final ctx = tester.element(find.text('x'));

    controller.sync(false, ctx, isLoginForm: false);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isFalse);
  });

  testWidgets('sync online dismisses showing sheet', (tester) async {
    final controller = OfflineSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('x'))),
      ),
    );
    final ctx = tester.element(find.text('x'));

    controller.sync(false, ctx, isLoginForm: true);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);

    controller.sync(true, ctx, isLoginForm: true);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isFalse);
  });

  testWidgets('dismissIfShowing when not showing is no-op', (tester) async {
    final controller = OfflineSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('x'))),
      ),
    );
    final ctx = tester.element(find.text('x'));

    controller.dismissIfShowing(ctx);
    await tester.pumpAndSettle();
    expect(controller.isShowing, isFalse);
  });
}
