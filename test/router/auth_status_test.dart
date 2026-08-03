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

  test('AuthStatusNotifier starts as unauthenticated by default', () {
    final notifier = AuthStatusNotifier();
    expect(notifier.currentStatus, AuthStatus.unauthenticated);
  });

  test('AuthStatusNotifier starts with provided status', () {
    final notifier = AuthStatusNotifier(AuthStatus.authenticated);
    expect(notifier.currentStatus, AuthStatus.authenticated);
  });

  test(
    'AuthStatusNotifier can be set to authenticated and emits on stream',
    () async {
      final notifier = AuthStatusNotifier();
      final statuses = <AuthStatus>[];
      final subscription = notifier.status.listen((status) {
        statuses.add(status);
      });

      notifier.setStatus(AuthStatus.authenticated);

      // Wait for stream events to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(notifier.currentStatus, AuthStatus.authenticated);
      expect(statuses, contains(AuthStatus.authenticated));
    },
  );

  test(
    'AuthStatusNotifier can be set to authenticated then back to unauthenticated',
    () async {
      final notifier = AuthStatusNotifier();
      notifier.setStatus(AuthStatus.authenticated);
      expect(notifier.currentStatus, AuthStatus.authenticated);
      notifier.setStatus(AuthStatus.unauthenticated);
      expect(notifier.currentStatus, AuthStatus.unauthenticated);
    },
  );

  test(
    'AuthStatusNotifier setStatus does not emit when status is unchanged',
    () async {
      final notifier = AuthStatusNotifier();
      final statuses = <AuthStatus>[];
      final subscription = notifier.status.listen((status) {
        statuses.add(status);
      });

      // setStatus with the same value should not emit
      notifier.setStatus(AuthStatus.unauthenticated);

      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(statuses, isEmpty);
    },
  );

  test('AuthStatusProvider is abstract and cannot be instantiated', () {
    expect(() => AuthStatusProvider(), throwsA(isA<TypeError>()));
  });
}
