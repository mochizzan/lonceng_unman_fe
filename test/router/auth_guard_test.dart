// test/router/auth_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';

/// Fake provider for testing — allows controlling auth status synchronously.
class FakeAuthStatusProvider implements AuthStatusProvider {
  FakeAuthStatusProvider(this._status);

  AuthStatus _status;

  @override
  AuthStatus get currentStatus => _status;

  @override
  final Stream<AuthStatus> status = const Stream.empty();

  set status(AuthStatus value) => _status = value;
}

void main() {
  group('authRedirect', () {
    late FakeAuthStatusProvider provider;

    setUp(() {
      provider = FakeAuthStatusProvider(AuthStatus.authenticated);
    });

    test('unauthenticated user on /home is redirected to /login', () {
      provider.status = AuthStatus.unauthenticated;

      final result = authRedirect(RouteNames.home, provider);

      expect(result, '/${RouteNames.login}');
    });

    test('authenticated user on /login is redirected to /home', () {
      provider.status = AuthStatus.authenticated;

      final result = authRedirect(RouteNames.login, provider);

      expect(result, '/${RouteNames.home}');
    });

    test('authenticated user on /home stays (no redirect)', () {
      provider.status = AuthStatus.authenticated;

      final result = authRedirect(RouteNames.home, provider);

      expect(result, isNull);
    });

    test('unauthenticated user on /login stays (no redirect)', () {
      provider.status = AuthStatus.unauthenticated;

      final result = authRedirect(RouteNames.login, provider);

      expect(result, isNull);
    });

    test('unknown status lets routing proceed (no redirect)', () {
      provider.status = AuthStatus.unknown;

      final result = authRedirect(RouteNames.home, provider);

      expect(result, isNull);
    });

    test('null matchedRoute with unauthenticated user redirects to /login', () {
      provider.status = AuthStatus.unauthenticated;

      final result = authRedirect(null, provider);

      expect(result, '/${RouteNames.login}');
    });

    test('authenticated user on /settings stays (no redirect)', () {
      provider.status = AuthStatus.authenticated;

      final result = authRedirect(RouteNames.settings, provider);

      expect(result, isNull);
    });
  });
}
