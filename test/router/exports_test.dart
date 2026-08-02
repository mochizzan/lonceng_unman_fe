// test/router/exports_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';

void main() {
  test('all route-related exports resolve', () {
    expect(RouteNames.login, 'login');
    expect(AuthStatus.authenticated, isNotNull);
    expect(AppErrorPage, isNotNull);
    expect(MainShellScaffold, isNotNull);
    expect(FloatingNavBar, isNotNull);
    expect(StubAuthStatusProvider, isNotNull);
  });
}
