import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_throttle.dart';

void main() {
  group('PullRefreshThrottle', () {
    const npm = '2211700006';
    const otherNpm = '2211700007';

    late DateTime fakeNow;
    late PullRefreshThrottle throttle;

    setUp(() {
      fakeNow = DateTime(2026, 9, 4, 10, 0, 0);
      throttle = PullRefreshThrottle(clock: () => fakeNow);
    });

    test('window 60 detik dan kuota 2 jalur berat per window', () {
      expect(PullRefreshThrottle.window, const Duration(seconds: 60));
      expect(PullRefreshThrottle.maxHeavyPerWindow, 2);
    });

    group('shouldThrottle', () {
      test('false untuk npm yang belum pernah hit', () {
        expect(throttle.shouldThrottle(npm), isFalse);
      });

      test('hit ke-1 dan ke-2 dalam 60 detik tidak di-throttle', () {
        // Cek sebelum hit ke-1: belum ada kuota terpakai.
        expect(throttle.shouldThrottle(npm), isFalse);
        throttle.recordHeavy(npm);

        // Cek sebelum hit ke-2: baru 1 hit dalam window.
        fakeNow = fakeNow.add(const Duration(seconds: 20));
        expect(throttle.shouldThrottle(npm), isFalse);
        throttle.recordHeavy(npm);
      });

      test('hit ke-3 dalam 60 detik di-throttle', () {
        throttle.recordHeavy(npm); // t=0

        fakeNow = fakeNow.add(const Duration(seconds: 20));
        throttle.recordHeavy(npm); // t=20

        fakeNow = fakeNow.add(const Duration(seconds: 20));
        expect(throttle.shouldThrottle(npm), isTrue); // t=40
      });

      test('false lagi setelah timestamp tertua kedaluwarsa (prune)', () {
        throttle.recordHeavy(npm); // t=0

        fakeNow = fakeNow.add(const Duration(seconds: 20));
        throttle.recordHeavy(npm); // t=20

        fakeNow = fakeNow.add(const Duration(seconds: 20));
        expect(throttle.shouldThrottle(npm), isTrue); // t=40, sanity

        // t=65: hit t=0 kedaluwarsa (selisih 65 > 60), sisa 1 hit.
        fakeNow = fakeNow.add(const Duration(seconds: 25));
        expect(throttle.shouldThrottle(npm), isFalse);
      });

      test('batas window: selisih == 60 dipertahankan, > 60 dibuang', () {
        final start = fakeNow;
        throttle.recordHeavy(npm); // t=0

        fakeNow = start.add(const Duration(seconds: 20));
        throttle.recordHeavy(npm); // t=20

        // Tepat 60 detik dari hit tertua: 60 > 60 salah, jadi dipertahankan.
        fakeNow = start.add(const Duration(seconds: 60));
        expect(throttle.shouldThrottle(npm), isTrue);

        // 61 detik: 61 > 60 benar, hit tertua dibuang, sisa 1.
        fakeNow = start.add(const Duration(seconds: 61));
        expect(throttle.shouldThrottle(npm), isFalse);
      });

      test('npm berbeda punya kuota terpisah', () {
        throttle.recordHeavy(npm); // t=0

        fakeNow = fakeNow.add(const Duration(seconds: 10));
        throttle.recordHeavy(npm); // t=10

        fakeNow = fakeNow.add(const Duration(seconds: 10)); // t=20
        expect(throttle.shouldThrottle(npm), isTrue);
        expect(throttle.shouldThrottle(otherNpm), isFalse);

        throttle.recordHeavy(otherNpm); // t=20
        expect(throttle.shouldThrottle(otherNpm), isFalse);

        fakeNow = fakeNow.add(const Duration(seconds: 10)); // t=30
        throttle.recordHeavy(otherNpm);
        expect(throttle.shouldThrottle(otherNpm), isTrue);

        // Aktivitas npm lain tidak memengaruhi kuota npm pertama.
        fakeNow = fakeNow.add(const Duration(seconds: 10)); // t=40
        expect(throttle.shouldThrottle(npm), isTrue);
      });
    });

    group('recordHeavy', () {
      test('membuang entri kedaluwarsa agar list tidak tumbuh', () {
        throttle.recordHeavy(npm); // t=0

        fakeNow = fakeNow.add(const Duration(seconds: 10));
        throttle.recordHeavy(npm); // t=10

        // Lompat jauh melewati window: kedua hit di atas kedaluwarsa.
        fakeNow = fakeNow.add(const Duration(seconds: 200)); // t=210
        throttle.recordHeavy(npm);

        fakeNow = fakeNow.add(const Duration(seconds: 10)); // t=220
        // Tanpa prune, 2 entri basi + 1 segar = 3 >= 2 → true (salah).
        // Dengan prune yang benar → hanya 1 entri segar → false.
        expect(throttle.shouldThrottle(npm), isFalse);

        throttle.recordHeavy(npm);
        expect(throttle.shouldThrottle(npm), isTrue);
      });
    });
  });
}
