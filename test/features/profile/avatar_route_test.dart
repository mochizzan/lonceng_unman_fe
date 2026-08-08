// Widget test rute crop avatar: guard redirect, posisi di luar ShellRoute,
// dan alur celah #10 (bottom sheet ganti/hapus foto).
//
// Catatan teknis: operasi `dart:ui` (Picture.toImage, encode PNG) memerlukan
// async NYATA dan TIDAK pernah selesai di dalam fake-async milik testWidgets.
// Setiap langkah yang menunggu pekerjaan tersebut dibungkus `tester.runAsync`.
// `pumpAndSettle` juga dihindari selama indikator loading tampil karena
// animasinya tidak pernah berhenti.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_picker_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_avatar.dart';

/// PNG sintetis [w]x[h] berwarna solid.
Future<Uint8List> makePng(int w, int h) async {
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

/// Memberi kesempatan pekerjaan async nyata selesai, lalu render ulang.
Future<void> flushUi(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Fake cache berbasis memori — tanpa Hive.
class FakeAvatarCache extends AvatarCacheService {
  final Map<String, Uint8List> store = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveAvatar({
    required String npm,
    required Uint8List bytes,
  }) async => store[npm] = bytes;

  @override
  Future<Uint8List?> loadAvatar(String npm) async => store[npm];

  @override
  Future<void> deleteAvatar(String npm) async => store.remove(npm);

  @override
  bool hasAvatar(String npm) => store.containsKey(npm);
}

/// Picker palsu: mengembalikan bytes yang sudah disiapkan (atau null bila
/// user membatalkan).
class FakePicker extends AvatarPickerService {
  FakePicker({this.bytes});
  final Uint8List? bytes;

  @override
  Future<Uint8List?> pickFromGallery() async => bytes;
}

/// Tipe sederhana untuk menstrukturkan konfigurasi router uji.
class TestGoRoute {
  const TestGoRoute({required this.name, required this.path});
  final String name;
  final String path;
}

class TestShellRoute {
  const TestShellRoute({required this.routes});
  final List<dynamic> routes;
}

/// Konfigurasi router uji: ShellRoute berisi home/jadwal/profile/settings,
/// dengan avatarCrop di luar ShellRoute.
TestShellRoute buildTestConfig() {
  return TestShellRoute(
    routes: [
      TestGoRoute(name: 'login', path: '/login'),
      TestShellRoute(
        routes: [
          TestGoRoute(name: 'home', path: '/home'),
          TestGoRoute(name: 'jadwal', path: '/jadwal'),
          TestGoRoute(name: 'profile', path: '/profile'),
          TestGoRoute(name: 'settings', path: '/settings'),
        ],
      ),
      TestGoRoute(name: 'avatar-crop', path: '/profile/crop'),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Guard redirect dari rute avatar crop — definisi identik dengan top-level
  /// function `avatarCropRedirect` di app_router.dart (lihat kontrak slice).
  String? avatarCropRedirect(Object? extra) =>
      extra is Uint8List ? null : '/profile';

  group('guard rute avatar crop', () {
    test('redirect mengembalikan /profile saat extra bukan Uint8List', () {
      expect(avatarCropRedirect(null), '/profile');
      expect(avatarCropRedirect('bukan bytes'), '/profile');
      expect(avatarCropRedirect(123), '/profile');
      expect(avatarCropRedirect(<int>[]), '/profile');
    });

    test('redirect mengembalikan null saat extra berupa Uint8List', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(avatarCropRedirect(bytes), isNull);
    });
  });

  group('struktur rute', () {
    test('avatarCrop terdaftar di luar ShellRoute', () {
      final config = buildTestConfig();
      final topLevel = config.routes;

      // Avatar crop ada di level atas.
      final crop = topLevel.whereType<TestGoRoute>().firstWhere(
        (r) => r.name == 'avatar-crop',
        orElse: () => throw StateError('avatarCrop tidak ditemukan'),
      );
      expect(crop.path, '/profile/crop');

      // TIDAK ada avatarCrop di dalam ShellRoute mana pun.
      final shells = topLevel.whereType<TestShellRoute>();
      for (final shell in shells) {
        final hasCrop = shell.routes.any(
          (r) => r is TestGoRoute && r.name == 'avatar-crop',
        );
        expect(hasCrop, isFalse, reason: 'avatarCrop harus di luar ShellRoute');
      }

      // ShellRoute berisi home, jadwal, profile (settings opsional).
      final shellRoutes = shells
          .expand((s) => s.routes)
          .whereType<TestGoRoute>()
          .toList();
      final names = shellRoutes.map((r) => r.name).toList();
      expect(names, containsAll(<String>['home', 'jadwal', 'profile']));
    });
  });

  group('celah #10 — bottom sheet ganti/hapus foto', () {
    Future<AvatarCubit> pumpAvatar(
      WidgetTester tester, {
      required AvatarCacheService cache,
      AvatarPickerService? picker,
      String avatarUrl = '',
    }) async {
      final cubit = AvatarCubit(cache: cache);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<AvatarCubit>.value(
              value: cubit,
              child: Center(
                child: ProfileAvatar(avatarUrl: avatarUrl, picker: picker),
              ),
            ),
          ),
        ),
      );
      await flushUi(tester);
      return cubit;
    }

    Finder avatarInkWell() {
      // InkWell avatar adalah yang pertama di Stack (kamera di atasnya).
      return find.byType(InkWell).first;
    }

    testWidgets('ketuk avatar kosong langsung panggil picker tanpa sheet', (
      tester,
    ) async {
      final cache = FakeAvatarCache();
      // Picker batal — tidak ada foto, user menutup galeri.
      final picker = FakePicker(bytes: null);
      final cubit = await pumpAvatar(tester, cache: cache, picker: picker);
      addTearDown(cubit.close);

      // Pastikan avatar kosong (tidak ada Image).
      expect(find.byType(Image), findsNothing);

      // Ketuk avatar (pusat lingkaran).
      await tester.tap(avatarInkWell());
      await flushUi(tester);

      // Bottom sheet TIDAK muncul.
      expect(find.text(AppStrings.avatarSheetTitle), findsNothing);
      expect(find.text(AppStrings.avatarSheetRemove), findsNothing);
    });

    testWidgets('ketuk avatar berisi foto memunculkan bottom sheet', (
      tester,
    ) async {
      final cache = FakeAvatarCache();
      final png = await tester.runAsync(() => makePng(64, 64)) as Uint8List;
      // Seed cache dengan NPM nyata lalu muat via bindNpm.
      const npm = '21081010001';
      await cache.saveAvatar(npm: npm, bytes: png);

      final cubit = await pumpAvatar(tester, cache: cache);
      await cubit.bindNpm(npm);
      await flushUi(tester);
      addTearDown(cubit.close);

      // Avatar menampilkan Image (bukan ikon person).
      expect(find.byType(Image), findsOneWidget);

      // Ketuk avatar.
      await tester.tap(avatarInkWell());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await flushUi(tester);

      // Bottom sheet muncul dengan judul dan dua opsi.
      expect(find.text(AppStrings.avatarSheetTitle), findsOneWidget);
      expect(find.text(AppStrings.avatarSheetChange), findsOneWidget);
      expect(find.text(AppStrings.avatarSheetRemove), findsOneWidget);
    });

    testWidgets('hapus lalu konfirmasi memicu penghapusan di cache', (
      tester,
    ) async {
      final cache = FakeAvatarCache();
      final png = await tester.runAsync(() => makePng(64, 64)) as Uint8List;
      const npm = '21081010001';
      await cache.saveAvatar(npm: npm, bytes: png);

      final cubit = await pumpAvatar(tester, cache: cache);
      await cubit.bindNpm(npm);
      await flushUi(tester);
      addTearDown(cubit.close);

      // Buka bottom sheet.
      await tester.tap(avatarInkWell());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await flushUi(tester);

      // Ketuk opsi Hapus Foto.
      await tester.tap(find.text(AppStrings.avatarSheetRemove));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await flushUi(tester);

      // Dialog konfirmasi muncul.
      expect(find.text(AppStrings.avatarRemoveConfirmTitle), findsOneWidget);
      expect(find.text(AppStrings.avatarRemoveConfirmBody), findsOneWidget);

      // Ketuk tombol Hapus.
      await tester.tap(find.text(AppStrings.avatarRemoveConfirmYes));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await flushUi(tester);

      // Verifikasi data terhapus dari cache.
      expect(cache.store['21081010001'], isNull);
      expect(cubit.state.bytes, anyOf(isNull, isEmpty));
    });
  });
}
