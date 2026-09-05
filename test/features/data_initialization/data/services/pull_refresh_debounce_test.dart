// Tests for PullRefreshDebounce tracker — sliding 3m (spec 2026-09-05 sliding 3m):
//   - first hit: shouldUseLight == false (heavy).
//   - within 180s: shouldUseLight == true (light).
//   - >= 180s: shouldUseLight == false (heavy again).
//   - touch resets timestamp (sliding: heavy maupun light sama-sama geser).
//   - per-NPM isolated.
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

    test('window 3 menit (sliding)', () {
      expect(PullRefreshDebounce.window, const Duration(minutes: 3));
    });

    test('hit pertama (belum ada catatan) → shouldUseLight == false', () {
      expect(debounce.shouldUseLight(npm), isFalse);
    });

    test('touch lalu cek dalam 180s → shouldUseLight == true', () {
      debounce.touch(npm, fakeNow);
      fakeNow = fakeNow.add(const Duration(seconds: 30));
      expect(debounce.shouldUseLight(npm), isTrue);
    });

    test('tepat 179s → true; tepat 180s → false (boundary)', () {
      // fakeNow = setUp baseline (2026-09-05 12:00:00).
      debounce.touch(npm, fakeNow);

      // 179s dari t0: < window → light.
      fakeNow = fakeNow.add(const Duration(seconds: 179));
      expect(
        debounce.shouldUseLight(npm),
        isTrue,
        reason: 'selisih 179s < window (180s) → light',
      );

      // +1s = 180s dari t0: >= window → boleh berat.
      fakeNow = fakeNow.add(const Duration(seconds: 1));
      expect(
        debounce.shouldUseLight(npm),
        isFalse,
        reason: 'selisih 180s >= window → boleh berat',
      );
    });

    test('touch kedua dalam window → reset timestamp', () {
      final t0 = DateTime(2026, 9, 5, 12, 0, 0);
      debounce.touch(npm, t0);

      // 30s setelah t0: masih window.
      fakeNow = t0.add(const Duration(seconds: 30));
      expect(debounce.shouldUseLight(npm), isTrue);

      // touch kedua di t=30 → reset timestamp ke 30.
      debounce.touch(npm, fakeNow);

      // 40s setelah reset (t=70): masih window dari timestamp baru.
      fakeNow = t0.add(const Duration(seconds: 70));
      expect(
        debounce.shouldUseLight(npm),
        isTrue,
        reason: '70s - 30s = 40s < window',
      );

      // 210s setelah t0 = 180s dari reset (t=30): tepat window, boleh berat.
      fakeNow = t0.add(const Duration(seconds: 210));
      expect(
        debounce.shouldUseLight(npm),
        isFalse,
        reason: '210s - 30s = 180s >= window',
      );
    });

    test('touch dari light juga geser jangkar (sliding)', () {
      // T0 heavy → T0+30s light (touch) → cek T0+200s harus masih light
      // karena jangkar sudah di T0+30s (sliding). Fixed lama jangkar tetap
      // di T0 sehingga T0+200s akan dianggap heavy — sliding berbeda.
      final t0 = DateTime(2026, 9, 5, 12, 0, 0);
      debounce.touch(npm, t0);

      // Light pull di T0+30s juga touch.
      fakeNow = t0.add(const Duration(seconds: 30));
      debounce.touch(npm, fakeNow);

      // 200s dari T0 = 170s dari touch terakhir (T0+30) → masih < 180 → light.
      fakeNow = t0.add(const Duration(seconds: 200));
      expect(
        debounce.shouldUseLight(npm),
        isTrue,
        reason: '200s - 30s = 170s < window (sliding)',
      );

      // 210s dari T0 = 180s dari touch terakhir → >= window → heavy.
      fakeNow = t0.add(const Duration(seconds: 210));
      expect(
        debounce.shouldUseLight(npm),
        isFalse,
        reason: '210s - 30s = 180s >= window → boleh berat',
      );
    });

    test('NPM berbeda terisolasi', () {
      final t0 = DateTime(2026, 9, 5, 12, 0, 0);
      debounce.touch(npm, t0);

      fakeNow = t0.add(const Duration(seconds: 10));
      expect(debounce.shouldUseLight(npm), isTrue);
      expect(
        debounce.shouldUseLight(otherNpm),
        isFalse,
        reason: 'otherNpm belum pernah touch',
      );
    });

    test(
      'touch setelah lewat window → shouldUseLight false lalu true lagi setelah touch',
      () {
        final t0 = DateTime(2026, 9, 5, 12, 0, 0);
        debounce.touch(npm, t0);

        fakeNow = t0.add(const Duration(minutes: 3));
        expect(debounce.shouldUseLight(npm), isFalse);

        // Touch lagi di tepat window → geser jangkar.
        debounce.touch(npm, fakeNow);
        fakeNow = fakeNow.add(const Duration(seconds: 10));
        expect(debounce.shouldUseLight(npm), isTrue);
      },
    );
  });
}
