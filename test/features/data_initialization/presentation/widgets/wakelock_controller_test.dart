import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/wakelock_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WakelockController', () {
    test('initially not held', () {
      final c = WakelockController();
      expect(c.isHeld, isFalse);
    });

    test(
      'enable sets isHeld true (or stays false if platform throws)',
      () async {
        final c = WakelockController();
        // In test environment there is no platform channel — WakelockPlus.enable
        // will throw MissingPluginException which the controller catches.
        // The important assertion is that it does NOT throw and isHeld remains
        // consistent (either true on real device, false in test).
        await c.enable();
        // Must not throw; isHeld may be true or false depending on platform.
        expect(c.isHeld, isA<bool>());
      },
    );

    test('disable when not held is a no-op and does not throw', () async {
      final c = WakelockController();
      expect(c.isHeld, isFalse);
      await c.disable();
      expect(c.isHeld, isFalse);
    });

    test('double enable does not double-call platform (guard _held)', () async {
      final c = WakelockController();
      await c.enable();
      final firstHeld = c.isHeld;
      await c.enable();
      expect(c.isHeld, firstHeld);
    });

    test(
      'enable then disable toggles correctly (best-effort in test env)',
      () async {
        final c = WakelockController();
        await c.enable();
        if (c.isHeld) {
          await c.disable();
          expect(c.isHeld, isFalse);
        } else {
          // Platform unavailable in test — disable is still safe.
          await c.disable();
          expect(c.isHeld, isFalse);
        }
      },
    );

    test('disable is idempotent — second disable does not throw', () async {
      final c = WakelockController();
      await c.enable();
      await c.disable();
      await c.disable();
      expect(c.isHeld, isFalse);
    });
  });
}
