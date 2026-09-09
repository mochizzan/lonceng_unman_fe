import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/services/fiam_service.dart';

class FakeFiamDelegate implements FiamDelegate {
  bool? lastSuppressed;
  bool? lastDataCollection;
  bool shouldThrow = false;

  @override
  Future<void> setMessagesSuppressed(bool suppress) async {
    if (shouldThrow) throw StateError('boom');
    lastSuppressed = suppress;
  }

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    lastDataCollection = enabled;
  }
}

void main() {
  group('FiamService', () {
    test('bind with unauthenticated suppresses FIAM', () async {
      final notifier = AuthStatusNotifier(AuthStatus.unauthenticated);
      final fake = FakeFiamDelegate();
      final service = FiamService(delegate: fake);
      await service.bind(notifier);
      expect(fake.lastSuppressed, isTrue);
      expect(fake.lastDataCollection, isFalse);
      service.dispose();
      notifier.dispose();
    });

    test('bind with authenticated does not suppress', () async {
      final notifier = AuthStatusNotifier(AuthStatus.authenticated);
      final fake = FakeFiamDelegate();
      final service = FiamService(delegate: fake);
      await service.bind(notifier);
      expect(fake.lastSuppressed, isFalse);
      expect(fake.lastDataCollection, isTrue);
      service.dispose();
      notifier.dispose();
    });

    test(
      'stream flip unauthenticated -> authenticated toggles suppression',
      () async {
        final notifier = AuthStatusNotifier(AuthStatus.unauthenticated);
        final fake = FakeFiamDelegate();
        final service = FiamService(delegate: fake);
        await service.bind(notifier);
        expect(fake.lastSuppressed, isTrue);
        expect(fake.lastDataCollection, isFalse);
        notifier.setStatus(AuthStatus.authenticated);
        // allow stream microtask to deliver
        await Future<void>.delayed(Duration.zero);
        expect(fake.lastSuppressed, isFalse);
        expect(fake.lastDataCollection, isTrue);
        service.dispose();
        notifier.dispose();
      },
    );

    test('underlying throw is swallowed, not propagated', () async {
      final notifier = AuthStatusNotifier(AuthStatus.unauthenticated);
      final fake = FakeFiamDelegate()..shouldThrow = true;
      final service = FiamService(delegate: fake);
      // should not throw
      await service.bind(notifier);
      expect(fake.lastSuppressed, isNull);
      service.dispose();
      notifier.dispose();
    });
  });
}
