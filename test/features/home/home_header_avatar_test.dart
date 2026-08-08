// Widget test header Home: avatar lokal hasil crop menjadi sumber utama.
//
// Membuktikan header Home membaca AvatarCubit global dan memprioritaskan foto
// lokal (bytes) di atas avatarUrl server, dengan ikon person sebagai fallback.
// Juga membuktikan header reaktif terhadap perubahan state cubit — cukup
// emit ulang, widget tidak perlu dibuat kembali.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/home_header.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';

/// Fake sederhana untuk AvatarCacheService — menyimpan bytes di memori.
///
/// Hanya menimpa method yang dipanggil cubit saat bindNpm; sisanya tidak
/// diperlukan untuk test ini.
class _FakeAvatarCache extends AvatarCacheService {
  final Map<String, Uint8List> store = {};

  @override
  Future<Uint8List?> loadAvatar(String npm) async => store[npm];

  @override
  Future<void> saveAvatar({
    required String npm,
    required Uint8List bytes,
  }) async {
    store[npm] = bytes;
  }

  @override
  Future<void> deleteAvatar(String npm) async {
    store.remove(npm);
  }
}

/// PNG sintetis [w]x[h] berwarna solid, dipakai sebagai avatar uji.
///
/// Seluruh operasi dart:ui (PictureRecorder, toByteData) butuh async NYATA dan
/// TIDAK pernah selesai di dalam fake-async milik testWidgets — karena itu
/// dibungkus tester.runAsync.
Future<Uint8List> _makePng(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF00AA00),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Memberi kesempatan pekerjaan async NYATA selesai, lalu render ulang.
///
/// Dibutuhkan karena perubahan state cubit yang terjadi SETELAH widget
/// terpasang tidak langsung terlihat pada satu `pump`: `emit` mengirim state
/// lewat stream, dan listener milik BlocBuilder baru dieksekusi saat microtask
/// dikuras di awal frame berikutnya. `setState` dari listener itu menjadwalkan
/// frame lagi, sehingga gambar baru muncul pada frame kedua.
Future<void> _flush(WidgetTester tester, {int rounds = 2}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Membungkus widget uji dengan provider cubit + MaterialApp (untuk Theme).
///
/// [key] dipasang pada [HomeHeader] agar test reaktivitas bisa membuktikan
/// elemen yang sama dipakai ulang — bukan widget yang dibuat kembali.
Widget _wrapWithCubit(AvatarCubit cubit, String avatarUrl, {Key? key}) {
  return MaterialApp(
    home: BlocProvider<AvatarCubit>.value(
      value: cubit,
      child: Scaffold(
        body: HomeHeader(
          key: key,
          dateText: 'Senin, 1 Januari 2026',
          userName: 'Budi',
          avatarUrl: avatarUrl,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'cubit punya bytes -> header menampilkan Image dari memori, bukan ikon',
    (tester) async {
      final cache = _FakeAvatarCache();
      final png = await tester.runAsync(() => _makePng(256, 256));
      // Preload avatar untuk NPM '123' sebelum bindNpm.
      cache.store['123'] = png!;

      final cubit = AvatarCubit(cache: cache);
      await cubit.bindNpm('123');
      addTearDown(cubit.close);

      await tester.pumpWidget(_wrapWithCubit(cubit, ''));
      await tester.pump();

      // Sumber #1 menang: Image (memory) tampil, ikon person TIDAK.
      expect(find.byType(Image), findsOneWidget, reason: 'harus Image.memory');
      expect(
        find.byIcon(Icons.person),
        findsNothing,
        reason: 'ikon person tidak boleh muncul bila bytes ada',
      );
    },
  );

  testWidgets(
    'tanpa bytes DAN avatarUrl kosong -> header menampilkan ikon person',
    (tester) async {
      final cache = _FakeAvatarCache();
      final cubit = AvatarCubit(cache: cache);
      // bindNpm ke NPM yang TIDAK punya avatar di cache.
      await cubit.bindNpm('456');
      addTearDown(cubit.close);

      await tester.pumpWidget(_wrapWithCubit(cubit, ''));
      await tester.pump();

      // Sumber #1 kosong, sumber #2 kosong -> fallback ikon person.
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(
        find.byType(Image),
        findsNothing,
        reason: 'tidak ada sumber gambar',
      );
    },
  );

  testWidgets(
    'perubahan state cubit (kosong -> berisi bytes) me-rebuild header',
    (tester) async {
      final cache = _FakeAvatarCache();
      final png = await tester.runAsync(() => _makePng(256, 256));
      // NPM 'B' nanti menyimpan avatar; preload cache-nya.
      cache.store['B'] = png!;

      final cubit = AvatarCubit(cache: cache);
      // Mulai dengan NPM 'A' yang TIDAK punya avatar -> fallback ikon.
      await cubit.bindNpm('A');
      addTearDown(cubit.close);

      // Key global dipakai untuk membuktikan elemen HomeHeader yang sama
      // dipertahankan lintas perubahan state — bukan dibuat ulang.
      final headerKey = GlobalKey();
      await tester.pumpWidget(_wrapWithCubit(cubit, '', key: headerKey));
      await tester.pump();
      final elementAwal = headerKey.currentContext;
      expect(elementAwal, isNotNull);

      // Awal: fallback ikon person (tidak ada bytes).
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      // NPM berganti ke 'B' yang punya avatar -> cubit load bytes dari cache.
      await cubit.bindNpm('B');
      expect(
        cubit.state.bytes,
        isNotNull,
        reason:
            'prasyarat: cubit sudah memegang bytes sebelum frame berikutnya',
      );

      // Emit cubit sampai ke BlocBuilder lewat stream: listener-nya berjalan
      // saat microtask dikuras di awal frame, dan setState di dalamnya
      // menjadwalkan frame kedua yang benar-benar merender gambar. Satu pump
      // saja tidak cukup — karena itu dipakai _flush.
      await _flush(tester);

      // Setelah rebuild: Image.memory tampil, ikon person hilang.
      expect(find.byType(Image), findsOneWidget, reason: 'Image.memory muncul');
      expect(
        find.byIcon(Icons.person),
        findsNothing,
        reason: 'ikon person harus hilang setelah bytes tersedia',
      );

      // Reaktivitas sungguhan: BlocBuilder di dalam header yang me-rebuild
      // bagian gambar; elemen HomeHeader-nya sendiri TIDAK dibuat ulang.
      expect(
        identical(elementAwal, headerKey.currentContext),
        isTrue,
        reason: 'HomeHeader tidak boleh dibuat ulang, hanya di-rebuild',
      );
    },
  );
}
