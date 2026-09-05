// patrol_test/login_api_isolated_test.dart
//
// Isolated test: only verifies that the production backend accepts the
// credentials. Runs without pumping any widgets — just exercises the
// ApiClient → /api/v1/lms/login → should return success.
//
// This test exists to verify network connectivity from the device's
// patrol runner isolate to the production backend. If this passes but
// login_e2e_test doesn't, the bug is in the form interaction (onChanged,
// controller, etc.) and not in network access.
//
// NOTE: the test name must NOT contain a path separator ('/') because
// Android Test Orchestrator uses the test name as part of the artifact
// filename and crashes with IllegalArgumentException if it does.
//
// Run:
//   patrol test -t patrol_test/login_api_isolated_test.dart \
//               --device 127.0.0.1:5557 --no-uninstall

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('production login API accepts valid NPM and password', ($) async {
    final api = ApiClient(baseUrl: AppStrings.apiBaseUrl);
    final data = await api.post(
      '/api/v1/lms/login',
      body: {'npm': '2211700006', 'password': 'Izzan027'},
    );
    expect(
      data['success'],
      isTrue,
      reason: 'Login API must return success for valid NPM+password',
    );
  });
}
