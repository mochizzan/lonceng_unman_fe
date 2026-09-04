// Tests for PullRefreshDebounce tracker (spec §5.5 poin 1):
//   - first hit: shouldUseLight == false (heavy).
//   - within 120s: shouldUseLight == true (light).
//   - >= 120s: shouldUseLight == false (heavy again).
//   - recordHeavy resets timestamp; per-NPM isolated.
//   - clock injectable; no Future.delayed.
//
// Hand-written, deterministic (no mockito/mocktail).

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_debounce.dart';

void main() {
  group('PullRefreshDebounce', () {
    const npm = '2211700006';
    const otherNpm = '2211700007';

    late DateTime fakeNow;
    late PullRefreshDebounce debounce;

    setUp(() {
      fakeNow = DateTime(2026, 9, 5, 12, 0, 0);
      debounce = PullRefreshDebounce(clock: () => fakeNow);
    });

    test('window 2 menit', () {
      expect(PullRefreshDebounce.window, const Duration(minutes: 2));
    });

    test('hit pertama (belum ada catatan) → shouldUseLight == false', () {
      expect(debounce.shouldUseLight(npm), isFalse);
    });

    test('recordHeavy lalu cek dalam 120s → shouldUseLight == true', () {
      debounce.recordHeavy(npm, fakeNow);
      fakeNow = fakeNow.add(const Duration(seconds: 30));
      expect(debounce.shouldUseLight(npm), isTrue);
    });

    test('tepat 119s → true; tepat 120s → false (boundary)', () {
      // fakeNow = setUp baseline (2026-09-05 12:00:00).
      debounce.recordHeavy(npm, fakeNow);

      // 119s dari t0: < window → light.
      fakeNow = fakeNow.add(const Duration(seconds: 119));
      expect(
        debounce.shouldUseLight(npm),
        isTrue,
        reason: 'selisih 119s < window (120s) → light',
      );

      // +1s = 120s dari t0: >= window → boleh berat.
      fakeNow = fakeNow.add(const Duration(seconds: 1));
      expect(
        debounce.shouldUseLight(npm),
        isFalse,
        reason: 'selisih 120s >= window → boleh berat',
      );
    });

    test('recordHeavy kedua dalam window → reset timestamp', () {
      final t0 = DateTime(2026, 9, 5, 12, 0, 0);
      debounce.recordHeavy(npm, t0);

      // 30s setelah t0: masih window.
      fakeNow = t0.add(const Duration(seconds: 30));
      expect(debounce.shouldUseLight(npm), isTrue);

      // recordHeavy kedua di t=30 → reset timestamp ke 30.
      debounce.recordHeavy(npm, fakeNow);

      // 40s setelah reset (t=70): masih window dari timestamp baru.
      fakeNow = t0.add(const Duration(seconds: 70));
      expect(
        debounce.shouldUseLight(npm),
        isTrue,
        reason: '70s - 30s = 40s < window',
      );

      // 200s setelah t0 = 170s dari reset (t=30): lewat window, boleh berat.
      fakeNow = t0.add(const Duration(seconds: 200));
      expect(
        debounce.shouldUseLight(npm),
        isFalse,
        reason: '200s - 30s = 170s >= window',
      );
    });

    test('NPM berbeda terisolasi', () {
      final t0 = DateTime(2026, 9, 5, 12, 0, 0);
      debounce.recordHeavy(npm, t0);

      fakeNow = t0.add(const Duration(seconds: 10));
      expect(debounce.shouldUseLight(npm), isTrue);
      expect(
        debounce.shouldUseLight(otherNpm),
        isFalse,
        reason: 'otherNpm belum pernah recordHeavy',
      );
    });

    test('recordHeavy setelah lewat window → boleh berat (false)', () {
      final t0 = DateTime(2026, 9, 5, 12, 0, 0);
      debounce.recordHeavy(npm, t0);

      fakeNow = t0.add(const Duration(minutes: 2));
      expect(debounce.shouldUseLight(npm), isFalse);
    });
  });
}
