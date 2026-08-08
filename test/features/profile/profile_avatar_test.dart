// Widget test ProfileAvatar: sumber gambar, status sibuk, dan alur
// pilih -> crop -> simpan lewat AvatarCubit.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_crop_service.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_picker_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/avatar_crop_page.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_avatar.dart';

const _npm = '21081010001';

class _FakeAvatarCache extends AvatarCacheService {
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

/// Picker palsu: mengembalikan bytes yang sudah disiapkan, atau null
/// (user membatalkan), atau melempar (galeri gagal dibuka).
class _FakePicker extends AvatarPickerService {
  _FakePicker({this.bytes, this.shouldThrow = false});

  final Uint8List? bytes;
  final bool shouldThrow;
  int callCount = 0;

  @override
  Future<Uint8List?> pickFromGallery() async {
    callCount++;
    if (shouldThrow) throw StateError('galeri gagal');
    return bytes;
  }
}

Future<Uint8List> _makePng(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF3366FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<void> _flush(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Guard redirect rute crop — definisi identik dengan top-level function
/// `avatarCropRedirect` di app_router.dart. Mengembalikan `/profile` bila
/// extra bukan Uint8List, null bila valid (izinkan navigasi).
String? _avatarCropRedirect(Object? extra) =>
    extra is Uint8List ? null : '/${RouteNames.profile}';

/// Membungkus ProfileAvatar dengan MaterialApp.router + GoRouter supaya
/// `context.pushNamed(RouteNames.avatarCrop, ...)` milik ProfileAvatar
/// menemukan router dan benar-benar membuka AvatarCropPage. Rute `/profile`
/// merender ProfileAvatar; rute `/profile/crop` merender AvatarCropPage.
Future<AvatarCubit> _pumpAvatar(
  WidgetTester tester, {
  required AvatarCacheService cache,
  AvatarPickerService? picker,
  String avatarUrl = '',
  String npm = _npm,
}) async {
  final cubit = AvatarCubit(cache: cache);
  final router = GoRouter(
    initialLocation: '/${RouteNames.profile}',
    routes: [
      GoRoute(
        name: RouteNames.profile,
        path: '/${RouteNames.profile}',
        builder: (context, state) => Scaffold(
          body: BlocProvider<AvatarCubit>.value(
            value: cubit..bindNpm(npm),
            child: Center(
              child: ProfileAvatar(avatarUrl: avatarUrl, picker: picker),
            ),
          ),
        ),
      ),
      GoRoute(
        name: RouteNames.avatarCrop,
        path: '/${RouteNames.profile}/crop',
        redirect: (context, state) => _avatarCropRedirect(state.extra),
        builder: (context, state) =>
            AvatarCropPage(imageBytes: state.extra! as Uint8List),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await _flush(tester);
  return cubit;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menampilkan ikon person saat belum ada foto', (tester) async {
    final cubit = await _pumpAvatar(tester, cache: _FakeAvatarCache());
    addTearDown(cubit.close);

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('menampilkan foto tersimpan dari cache', (tester) async {
    final cache = _FakeAvatarCache();
    cache.store[_npm] =
        await tester.runAsync(() => _makePng(64, 64)) as Uint8List;

    final cubit = await _pumpAvatar(tester, cache: cache);
    addTearDown(cubit.close);

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('membatalkan pemilihan mengembalikan tombol kamera', (
    tester,
  ) async {
    final picker = _FakePicker(bytes: null);
    final cubit = await _pumpAvatar(
      tester,
      cache: _FakeAvatarCache(),
      picker: picker,
    );
    addTearDown(cubit.close);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await _flush(tester);

    expect(picker.callCount, 1);
    expect(cubit.state, isA<AvatarReady>());
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('galeri gagal menampilkan SnackBar kesalahan', (tester) async {
    final picker = _FakePicker(shouldThrow: true);
    final cubit = await _pumpAvatar(
      tester,
      cache: _FakeAvatarCache(),
      picker: picker,
    );
    addTearDown(cubit.close);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await _flush(tester);

    expect(find.text(AppStrings.avatarPickError), findsOneWidget);
  });

  testWidgets(
    'alur penuh: pilih foto -> crop -> simpan menulis PNG 256x256 ke cache',
    (tester) async {
      final cache = _FakeAvatarCache();
      final source = await tester.runAsync(() => _makePng(400, 300));
      final picker = _FakePicker(bytes: source);

      final cubit = await _pumpAvatar(tester, cache: cache, picker: picker);
      addTearDown(cubit.close);

      // Buka galeri -> halaman crop terbuka.
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _flush(tester);

      expect(find.byType(AvatarCropPage), findsOneWidget);

      // Simpan hasil crop.
      await tester.tap(find.text(AppStrings.avatarCropSave));
      await _flush(tester, rounds: 8);
      await tester.pump(const Duration(milliseconds: 400));
      await _flush(tester);

      final saved = cache.store[_npm];
      expect(saved, isNotNull, reason: 'avatar harus tersimpan di cache');
      expect(saved!.isNotEmpty, isTrue);

      final decoded = await tester.runAsync(
        () => AvatarCropService.decode(saved),
      );
      addTearDown(decoded!.dispose);
      expect(decoded.width, AvatarCropService.outputSize);
      expect(decoded.height, AvatarCropService.outputSize);

      // State cubit ikut memperbarui tampilan.
      expect(cubit.state.bytes, saved);
    },
  );

  testWidgets('avatar dua NPM berbeda tidak saling menimpa', (tester) async {
    final cache = _FakeAvatarCache();
    final pngA = await tester.runAsync(() => _makePng(32, 32)) as Uint8List;
    cache.store['21081010001'] = pngA;

    final cubitB = await _pumpAvatar(tester, cache: cache, npm: '21081010002');
    addTearDown(cubitB.close);

    // NPM kedua belum punya avatar meski NPM pertama sudah.
    expect(cubitB.state.bytes, isNull);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(cache.store['21081010001'], pngA);
  });
}
