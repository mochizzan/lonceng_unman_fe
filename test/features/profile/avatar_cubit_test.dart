// Test AvatarCubit: pemuatan, penyimpanan, penghapusan, dan isolasi per-NPM.

import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveAvatar({
    required String npm,
    required Uint8List bytes,
  }) async {
    if (throwOnSave) throw StateError('gagal simpan');
    store[npm] = bytes;
  }

  @override
  Future<Uint8List?> loadAvatar(String npm) async {
    if (throwOnLoad) throw StateError('gagal baca');
    return store[npm];
  }

  @override
  Future<void> deleteAvatar(String npm) async => store.remove(npm);

  @override
  bool hasAvatar(String npm) => store.containsKey(npm);
}

final _png = Uint8List.fromList([1, 2, 3, 4]);
final _otherPng = Uint8List.fromList([9, 9, 9]);

void main() {
  late _FakeAvatarCache cache;

  setUp(() => cache = _FakeAvatarCache());

  group('load', () {
    blocTest<AvatarCubit, AvatarState>(
      'emit AvatarReady(null) saat belum ada avatar',
      build: () => AvatarCubit(npm: '21081010001', cache: cache),
      act: (cubit) => cubit.load(),
      expect: () => [const AvatarReady(null)],
    );

    blocTest<AvatarCubit, AvatarState>(
      'emit AvatarReady dengan bytes tersimpan',
      build: () {
        cache.store['21081010001'] = _png;
        return AvatarCubit(npm: '21081010001', cache: cache);
      },
      act: (cubit) => cubit.load(),
      expect: () => [AvatarReady(_png)],
    );

    blocTest<AvatarCubit, AvatarState>(
      'NPM kosong langsung AvatarReady(null) tanpa menyentuh cache',
      build: () => AvatarCubit(npm: '', cache: cache),
      act: (cubit) => cubit.load(),
      expect: () => [const AvatarReady(null)],
    );

    blocTest<AvatarCubit, AvatarState>(
      'kegagalan baca cache tidak melempar, jatuh ke AvatarReady(null)',
      build: () {
        cache.throwOnLoad = true;
        return AvatarCubit(npm: '21081010001', cache: cache);
      },
      act: (cubit) => cubit.load(),
      expect: () => [const AvatarReady(null)],
    );
  });

  group('save', () {
    blocTest<AvatarCubit, AvatarState>(
      'emit Processing lalu Ready, dan bytes tertulis ke cache',
      build: () => AvatarCubit(npm: '21081010001', cache: cache),
      act: (cubit) => cubit.save(_png),
      expect: () => [const AvatarProcessing(), AvatarReady(_png)],
      verify: (_) => expect(cache.store['21081010001'], _png),
    );

    blocTest<AvatarCubit, AvatarState>(
      'kegagalan simpan emit AvatarFailure dan mempertahankan avatar lama',
      build: () {
        cache.store['21081010001'] = _png;
        cache.throwOnSave = true;
        return AvatarCubit(npm: '21081010001', cache: cache);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.save(_otherPng);
      },
      expect: () => [
        AvatarReady(_png),
        AvatarProcessing(bytes: _png),
        AvatarFailure(AppStrings.avatarSaveError, bytes: _png),
      ],
    );

    blocTest<AvatarCubit, AvatarState>(
      'NPM kosong gagal menyimpan',
      build: () => AvatarCubit(npm: '', cache: cache),
      act: (cubit) => cubit.save(_png),
      expect: () => [const AvatarFailure(AppStrings.avatarSaveError)],
      verify: (_) => expect(cache.store, isEmpty),
    );
  });

  group('remove', () {
    blocTest<AvatarCubit, AvatarState>(
      'menghapus avatar dari cache',
      build: () {
        cache.store['21081010001'] = _png;
        return AvatarCubit(npm: '21081010001', cache: cache);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.remove();
      },
      expect: () => [
        AvatarReady(_png),
        AvatarProcessing(bytes: _png),
        const AvatarReady(null),
      ],
      verify: (_) => expect(cache.store.containsKey('21081010001'), isFalse),
    );
  });

  group('isolasi per-NPM', () {
    test('avatar dua NPM berbeda tidak saling menimpa', () async {
      final a = AvatarCubit(npm: '21081010001', cache: cache);
      final b = AvatarCubit(npm: '21081010002', cache: cache);

      await a.save(_png);
      await b.save(_otherPng);

      await a.load();
      await b.load();

      expect(a.state.bytes, _png);
      expect(b.state.bytes, _otherPng);

      // Menghapus milik A tidak mempengaruhi B.
      await a.remove();
      await b.load();
      expect(a.state.bytes, isNull);
      expect(b.state.bytes, _otherPng);

      await a.close();
      await b.close();
    });
  });

  group('status proses dari layer presentation', () {
    blocTest<AvatarCubit, AvatarState>(
      'markProcessing lalu cancelProcessing mengembalikan avatar semula',
      build: () {
        cache.store['21081010001'] = _png;
        return AvatarCubit(npm: '21081010001', cache: cache);
      },
      act: (cubit) async {
        await cubit.load();
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
        cache.store['21081010001'] = _png;
        return AvatarCubit(npm: '21081010001', cache: cache);
      },
      act: (cubit) async {
        await cubit.load();
        cubit.reportFailure(AppStrings.avatarPickError);
      },
      expect: () => [
        AvatarReady(_png),
        AvatarFailure(AppStrings.avatarPickError, bytes: _png),
      ],
    );
  });
}
