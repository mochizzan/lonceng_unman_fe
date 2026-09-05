// patrol_test/setup_verification_test.dart
//
// Minimal test that mirrors the official Patrol "getting started" example.
// Verifies the native instrumentation runner (PatrolTestRunner) and the
// Gradle plugin are wired correctly: pumping a tiny widget works, and
// `$.native.pressHome()` exits the app to the device home screen.
//
// If THIS test fails, the issue is in the Patrol setup (gradle / runner /
// CLI), NOT in the app under test.
//
// Run:
//   patrol test -t patrol_test/setup_verification_test.dart \
//               --device 127.0.0.1:5557

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('patrol native plumbing works (pump widget + press home)', (
    $,
  ) async {
    await $.pumpWidgetAndSettle(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('app')),
          backgroundColor: Colors.blue,
        ),
      ),
    );

    expect($('app'), findsOneWidget);

    if (!Platform.isMacOS) {
      await $.native.pressHome();
    }
  });
}
