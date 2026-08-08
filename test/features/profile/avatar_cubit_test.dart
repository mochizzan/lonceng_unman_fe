// Test AvatarCubit: pengikatan NPM, pemuatan, penyimpanan, penghapusan,
// isolasi antar-akun, keamanan emit setelah close, dan rollback saat gagal.

import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';

/// Fake cache berbasis memori — tanpa Hive, sesuai konvensi repo
/// (hand-written fakes, tanpa mockito/mocktail).
class _FakeAvatarCache extends AvatarCacheService {
  final Map<String, Uint8List> store = {};
  bool throwOnSave = false;
  bool throwOnLoad = false;
  bool throwOnDelete = false;

  /// Jumlah pemanggilan saveAvatar — dipakai membuktikan simpan ganda ditolak.
  int saveCallCount = 0;

  /// Bila diisi, saveAvatar menunggu completer ini sebelum selesai.
  Completer<void>? saveGate;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveAvatar({
    required String npm,
    required Uint8List bytes,
  }) async {
    saveCallCount++;
    if (saveGate != null) await saveGate!.future;
    if (throwOnSave) throw StateError('gagal simpan');
    store[npm] = bytes;
  }

  @override
  Future<Uint8List?> loadAvatar(String npm) async {
    if (throwOnLoad) throw StateError('gagal baca');
    return store[npm];
  }

  @override
  Future<void> deleteAvatar(String npm) async {
    if (throwOnDelete) throw StateError('gagal hapus');
    store.remove(npm);
  }

  @override
  bool hasAvatar(String npm) => store.containsKey(npm);
}

/// Fake kredensial akademik untuk menguji [AvatarCubit.bootstrap].
class _FakeAcademicCache extends AcademicCacheService {
  _FakeAcademicCache({this.credentials, this.throwOnLoad = false});

  final Map<String, String>? credentials;
  final bool throwOnLoad;

  @override
  Future<void> initialize() async {}

  @override
  Future<Map<String, String>?> loadCredentials() async {
    if (throwOnLoad) throw StateError('gagal baca kredensial');
    return credentials;
  }
}

final _png = Uint8List.fromList([1, 2, 3, 4]);
final _otherPng = Uint8List.fromList([9, 9, 9]);

const _npmA = '21081010001';
const _npmB = '21081010002';

void main() {
  late _FakeAvatarCache cache;

  setUp(() => cache = _FakeAvatarCache());

  group('bindNpm', () {
    blocTest<AvatarCubit, AvatarState>(
      'emit AvatarReady(null) saat NPM belum punya avatar',
      build: () => AvatarCubit(cache: cache),
      act: (cubit) => cubit.bindNpm(_npmA),
      expect: () => [const AvatarReady(null)],
    );

    blocTest<AvatarCubit, AvatarState>(
      'emit AvatarReady dengan bytes tersimpan',
      build: () {
        cache.store[_npmA] = _png;
        return AvatarCubit(cache: cache);
      },
      act: (cubit) => cubit.bindNpm(_npmA),
      expect: () => [AvatarReady(_png)],
      verify: (cubit) => expect(cubit.npm, _npmA),
    );

    blocTest<AvatarCubit, AvatarState>(
      'NPM kosong langsung AvatarReady(null) tanpa menyentuh cache',
      build: () {
        cache.throwOnLoad = true; // Terlempar bila cache benar-benar dibaca.
        return AvatarCubit(cache: cache);
      },
      act: (cubit) => cubit.bindNpm(''),
      // NPM awal juga '' sehingga bindNpm('') adalah no-op murni.
      expect: () => <AvatarState>[],
    );

    blocTest<AvatarCubit, AvatarState>(
      'kegagalan baca cache tidak melempar, jatuh ke AvatarReady(null)',
      build: () {
        cache.throwOnLoad = true;
        return AvatarCubit(cache: cache);
      },
      act: (cubit) => cubit.bindNpm(_npmA),
      expect: () => [const AvatarReady(null)],
    );

    blocTest<AvatarCubit, AvatarState>(
      'bindNpm dengan NPM yang sama adalah no-op (tidak emit ulang)',
      build: () {
        cache.store[_npmA] = _png;
        return AvatarCubit(cache: cache);
      },
      act: (cubit) async {
        await cubit.bindNpm(_npmA);
        await cubit.bindNpm(_npmA);
        await cubit.bindNpm(_npmA);
      },
      expect: () => [AvatarReady(_png)],
    );
  });

  group('bootstrap', () {
    test('mengikat NPM dari kredensial tersimpan', () async {
      cache.store[_npmA] = _png;
      final cubit = AvatarCubit(
        cache: cache,
        academicCache: _FakeAcademicCache(
          credentials: {'npm': _npmA, 'password': 'x'},
        ),
      );

      await cubit.bootstrap();

      expect(cubit.npm, _npmA);
      expect(cubit.state.bytes, _png);
      await cubit.close();
    });

    test('tanpa kredensial berujung AvatarReady(null)', () async {
      final cubit = AvatarCubit(
        cache: cache,
        academicCache: _FakeAcademicCache(),
      );

      await cubit.bootstrap();

      expect(cubit.npm, isEmpty);
      expect(cubit.state, const AvatarReady(null));
      await cubit.close();
    });

    test('kegagalan baca kredensial tidak melempar', () async {
      final cubit = AvatarCubit(
        cache: cache,
        academicCache: _FakeAcademicCache(throwOnLoad: true),
      );

      await expectLater(cubit.bootstrap(), completes);

      expect(cubit.state, const AvatarReady(null));
      await cubit.close();
    });
  });

  group('save', () {
    blocTest<AvatarCubit, AvatarState>(
      'emit Processing lalu Ready, dan bytes tertulis ke cache',
      build: () => AvatarCubit(cache: cache),
      act: (cubit) async {
        await cubit.bindNpm(_npmA);
        await cubit.save(_png);
      },
      expect: () => [
        const AvatarReady(null),
        const AvatarProcessing(),
        AvatarReady(_png),
      ],
      verify: (_) => expect(cache.store[_npmA], _png),
    );

    blocTest<AvatarCubit, AvatarState>(
      'NPM kosong gagal menyimpan',
      build: () => AvatarCubit(cache: cache),
      act: (cubit) => cubit.save(_png),
      expect: () => [const AvatarFailure(AppStrings.avatarSaveError)],
      verify: (_) => expect(cache.store, isEmpty),
    );
  });

  group('remove', () {
    blocTest<AvatarCubit, AvatarState>(
      'menghapus avatar dari cache',
      build: () {
        cache.store[_npmA] = _png;
        return AvatarCubit(cache: cache);
      },
      act: (cubit) async {
        await cubit.bindNpm(_npmA);
        await cubit.remove();
      },
      expect: () => [
        AvatarReady(_png),
        AvatarProcessing(bytes: _png),
        const AvatarReady(null),
      ],
      verify: (_) => expect(cache.store.containsKey(_npmA), isFalse),
    );
  });

  group('isolasi per-NPM', () {
    test('avatar dua NPM berbeda tidak saling menimpa', () async {
      final cubit = AvatarCubit(cache: cache);

      await cubit.bindNpm(_npmA);
      await cubit.save(_png);
      await cubit.bindNpm(_npmB);
      await cubit.save(_otherPng);

      await cubit.bindNpm(_npmA);
      expect(cubit.state.bytes, _png);
      await cubit.bindNpm(_npmB);
      expect(cubit.state.bytes, _otherPng);

      // Menghapus milik B tidak mempengaruhi A.
      await cubit.remove();
      expect(cubit.state.bytes, isNull);
      await cubit.bindNpm(_npmA);
      expect(cubit.state.bytes, _png);

      await cubit.close();
    });
  });

  group('celah #1 - kebocoran avatar antar-akun', () {
    test(
      'setelah reset, akun baru tanpa foto TIDAK menampilkan foto akun lama',
      () async {
        cache.store[_npmA] = _png;
        final cubit = AvatarCubit(cache: cache);

        await cubit.bindNpm(_npmA);
        expect(cubit.state.bytes, _png, reason: 'foto A harus tampil dulu');

        // Logout.
        cubit.reset();
        expect(cubit.npm, isEmpty);
        expect(cubit.state.bytes, isNull);

        // Login akun B yang belum punya foto.
        await cubit.bindNpm(_npmB);
        expect(
          cubit.state.bytes,
          isNull,
          reason: 'foto akun A tidak boleh bocor ke akun B',
        );

        await cubit.close();
      },
    );

    test(
      'reset tidak menghapus data — foto A masih ada setelah login ulang',
      () async {
        cache.store[_npmA] = _png;
        final cubit = AvatarCubit(cache: cache);

        await cubit.bindNpm(_npmA);
        cubit.reset();
        await cubit.bindNpm(_npmB);
        await cubit.bindNpm(_npmA);

        expect(cubit.state.bytes, _png);
        expect(cache.store[_npmA], _png);

        await cubit.close();
      },
    );
  });

  group('celah #2 - emit setelah close', () {
    test('close saat save berjalan tidak melempar StateError', () async {
      final gate = Completer<void>();
      cache.saveGate = gate;
      final cubit = AvatarCubit(cache: cache);
      await cubit.bindNpm(_npmA);

      final pending = cubit.save(_png);
      // Cubit ditutup selagi penulisan tertahan di gate.
      await cubit.close();
      gate.complete();

      await expectLater(pending, completes);
    });

    test('close saat bindNpm berjalan tidak melempar StateError', () async {
      final cubit = AvatarCubit(cache: cache);
      final pending = cubit.bindNpm(_npmA);
      await cubit.close();

      await expectLater(pending, completes);
    });

    test('close saat remove berjalan tidak melempar StateError', () async {
      final gate = Completer<void>();
      cache.store[_npmA] = _png;
      cache.saveGate = gate;
      final cubit = AvatarCubit(cache: cache);
      await cubit.bindNpm(_npmA);

      // remove() memakai deleteAvatar; pakai save() lalu remove untuk memastikan
      // jalur emit-setelah-await juga aman saat cubit ditutup.
      final pending = cubit.save(_otherPng);
      await cubit.close();
      gate.complete();
      await pending;

      await expectLater(cubit.remove(), completes);
    });
  });

  group('celah #8 - rollback saat penulisan gagal', () {
    test('gagal simpan mengembalikan bytes ke foto SEBELUMNYA', () async {
      cache.store[_npmA] = _png;
      cache.throwOnSave = true;
      final cubit = AvatarCubit(cache: cache);

      await cubit.bindNpm(_npmA);
      await cubit.save(_otherPng);

      expect(cubit.state, isA<AvatarFailure>());
      expect(
        cubit.state.bytes,
        _png,
        reason: 'layar harus kembali ke foto lama, bukan foto baru yang gagal',
      );
      // Penyimpanan tetap berisi foto lama — layar dan storage konsisten.
      expect(cache.store[_npmA], _png);

      await cubit.close();
    });

    test('gagal hapus mengembalikan bytes ke foto sebelumnya', () async {
      cache.store[_npmA] = _png;
      cache.throwOnDelete = true;
      final cubit = AvatarCubit(cache: cache);

      await cubit.bindNpm(_npmA);
      await cubit.remove();

      expect(cubit.state, isA<AvatarFailure>());
      expect(cubit.state.bytes, _png);
      expect(cache.store[_npmA], _png);

      await cubit.close();
    });

    test(
      'kegagalan tulis tidak mengunci cubit — simpan berikutnya berhasil',
      () async {
        cache.store[_npmA] = _png;
        cache.throwOnSave = true;
        final cubit = AvatarCubit(cache: cache);
        await cubit.bindNpm(_npmA);

        await cubit.save(_otherPng);
        expect(cubit.state, isA<AvatarFailure>());

        // Percobaan kedua setelah cache pulih harus tetap diproses.
        cache.throwOnSave = false;
        await cubit.save(_otherPng);

        expect(cubit.state, AvatarReady(_otherPng));
        expect(cache.store[_npmA], _otherPng);
        expect(cache.saveCallCount, 2);

        await cubit.close();
      },
    );
  });

  group('celah #3 - permintaan tulis ganda ditolak', () {
    test(
      'save kedua saat yang pertama berjalan hanya memanggil cache sekali',
      () async {
        final gate = Completer<void>();
        cache.saveGate = gate;
        final cubit = AvatarCubit(cache: cache);
        await cubit.bindNpm(_npmA);

        final first = cubit.save(_png);
        // Permintaan kedua datang saat yang pertama belum selesai.
        await cubit.save(_otherPng);
        expect(cache.saveCallCount, 1);

        gate.complete();
        await first;

        expect(cache.saveCallCount, 1);
        expect(cubit.state, AvatarReady(_png));
        expect(cache.store[_npmA], _png);

        await cubit.close();
      },
    );

    test('remove saat save berjalan diabaikan', () async {
      final gate = Completer<void>();
      cache.saveGate = gate;
      final cubit = AvatarCubit(cache: cache);
      await cubit.bindNpm(_npmA);

      final first = cubit.save(_png);
      await cubit.remove();

      gate.complete();
      await first;

      expect(cache.store[_npmA], _png, reason: 'remove harus diabaikan');
      await cubit.close();
    });

    test(
      'save tetap jalan meski layer presentation sudah markProcessing',
      () async {
        final cubit = AvatarCubit(cache: cache);
        await cubit.bindNpm(_npmA);

        // Pola nyata di ProfileAvatar._pickAndCrop.
        cubit.markProcessing();
        await cubit.save(_png);

        expect(cache.saveCallCount, 1);
        expect(cubit.state, AvatarReady(_png));

        await cubit.close();
      },
    );
  });

  group('status proses dari layer presentation', () {
    blocTest<AvatarCubit, AvatarState>(
      'markProcessing lalu cancelProcessing mengembalikan avatar semula',
      build: () {
        cache.store[_npmA] = _png;
        return AvatarCubit(cache: cache);
      },
      act: (cubit) async {
        await cubit.bindNpm(_npmA);
        cubit.markProcessing();
        cubit.cancelProcessing();
      },
      expect: () => [
        AvatarReady(_png),
        AvatarProcessing(bytes: _png),
        AvatarReady(_png),
      ],
    );

    blocTest<AvatarCubit, AvatarState>(
      'reportFailure menampilkan pesan tanpa menghapus avatar',
      build: () {
        cache.store[_npmA] = _png;
        return AvatarCubit(cache: cache);
      },
      act: (cubit) async {
        await cubit.bindNpm(_npmA);
        cubit.reportFailure(AppStrings.avatarPickError);
      },
      expect: () => [
        AvatarReady(_png),
        AvatarFailure(AppStrings.avatarPickError, bytes: _png),
      ],
    );
  });
}
