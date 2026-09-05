// integration_test/app_smoke_test.dart
//
// Minimal Flutter integration_test to verify the integration_test package
// runs on the connected Android device. If THIS passes but Patrol doesn't,
// the bug is in Patrol's test discovery, not in the app.
//
// Run with:
//   flutter test integration_test/app_smoke_test.dart \
//     -d 127.0.0.1:5557

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders a tiny MaterialApp and finds a text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('integration works'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('integration works'), findsOneWidget);
  });
}
