// patrol_test/app_launch_smoke_test.dart
//
// Simple smoke test for Lonceng UnMan.
// Launches the app on a connected device, waits for Home to settle, and
// asserts the "Lihat KHS" button (a known widget Key) is visible.
//
// Assumes the app is already logged in (Hive cache holds credentials).
//
// Run:
//   patrol test -t patrol_test/app_launch_smoke_test.dart \
//               --device 127.0.0.1:5557

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/main.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('app launches and Home screen renders "Lihat KHS" button', (
    $,
  ) async {
    // Pump the real app entry widget. Patrol will start the native
    // instrumentation before this runs.
    await $.pumpWidgetAndSettle(const LoncengUnmanApp());

    // Wait for the auth/initialization pipeline to settle. Splash +
    // Hive init can take a few seconds on cold launch.
    await $.pumpAndSettle(timeout: const Duration(seconds: 10));

    // "lihat_khs_button" is a Key defined in
    // lib/features/home/presentation/widgets/quick_stats.dart. Finding it
    // proves the Home page rendered after auth + data init.
    expect(
      $(#lihat_khs_button),
      findsOneWidget,
      reason: 'Expected Home page to render with the "Lihat KHS" button.',
    );
  });
}
