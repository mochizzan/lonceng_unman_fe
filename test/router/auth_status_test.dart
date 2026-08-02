// test/router/auth_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';

void main() {
  test('AuthStatus enum has 3 states', () {
    expect(AuthStatus.values.length, 3);
    expect(AuthStatus.unknown, isNotNull);
    expect(AuthStatus.authenticated, isNotNull);
    expect(AuthStatus.unauthenticated, isNotNull);
  });

  test('StubAuthStatusProvider always returns authenticated', () {
    final provider = StubAuthStatusProvider();
    expect(provider.currentStatus, AuthStatus.authenticated);
  });

  test('StubAuthStatusProvider status stream is empty', () async {
    final provider = StubAuthStatusProvider();
    expect(await provider.status.isEmpty, isTrue);
  });

  test('AuthStatusProvider is abstract and cannot be instantiated', () {
    expect(() => AuthStatusProvider(), throwsA(isA<TypeError>()));
  });
}
