// Widget test AvatarCropPage: render, batal, dan simpan.
//
// Catatan teknis: seluruh operasi `dart:ui` (Picture.toImage, decode PNG,
// encode PNG) membutuhkan async NYATA dan TIDAK pernah selesai di dalam
// fake-async milik testWidgets. Karena itu setiap langkah yang menunggu
// pekerjaan tersebut dibungkus `tester.runAsync`.
//
// `pumpAndSettle` juga dihindari selama indikator loading tampil karena
// animasinya tidak pernah berhenti.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_crop_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/avatar_crop_page.dart';

/// PNG sintetis [w]x[h] berwarna solid, dipakai sebagai gambar sumber.
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

/// Memberi kesempatan pekerjaan async nyata selesai, lalu render ulang.
Future<void> _flush(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Uint8List? _result;
bool _resultReceived = false;

Future<void> _openCropPage(WidgetTester tester, Uint8List bytes) async {
  _result = null;
  _resultReceived = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final value = await Navigator.of(context).push<Uint8List>(
                  MaterialPageRoute(
                    builder: (_) => AvatarCropPage(imageBytes: bytes),
                  ),
                );
                _result = value;
                _resultReceived = true;
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('buka'));
  // Selesaikan transisi rute tanpa pumpAndSettle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await _flush(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menampilkan judul, petunjuk, dan area crop', (tester) async {
    final png = await tester.runAsync(() => _makePng(400, 300));
    await _openCropPage(tester, png!);

    expect(find.text(AppStrings.avatarCropTitle), findsOneWidget);
    expect(find.text(AppStrings.avatarCropHint), findsOneWidget);
    expect(find.text(AppStrings.avatarCropSave), findsOneWidget);
    expect(find.text(AppStrings.avatarCropCancel), findsOneWidget);
    expect(
      find.byType(InteractiveViewer),
      findsOneWidget,
      reason: 'gambar harus bisa digeser dan di-zoom oleh user',
    );
  });

  testWidgets('tombol Batal menutup halaman tanpa hasil', (tester) async {
    final png = await tester.runAsync(() => _makePng(400, 300));
    await _openCropPage(tester, png!);

    await tester.tap(find.text(AppStrings.avatarCropCancel));
    await tester.pump();
    // Tunggu animasi pop rute benar-benar selesai sebelum memeriksa
    // bahwa halaman sudah lepas dari widget tree.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(_resultReceived, isTrue);
    expect(_result, isNull);
    expect(find.byType(AvatarCropPage), findsNothing);
  });

  testWidgets('tombol Simpan mengembalikan PNG 256x256', (tester) async {
    final png = await tester.runAsync(() => _makePng(400, 300));
    await _openCropPage(tester, png!);

    await tester.tap(find.text(AppStrings.avatarCropSave));
    await _flush(tester, rounds: 8);
    await tester.pump(const Duration(milliseconds: 400));
    await _flush(tester);

    expect(_result, isNotNull, reason: 'Simpan harus mengembalikan bytes PNG');
    expect(_result!.isNotEmpty, isTrue);

    final decoded = await tester.runAsync(
      () => AvatarCropService.decode(_result!),
    );
    addTearDown(decoded!.dispose);
    expect(decoded.width, AvatarCropService.outputSize);
    expect(decoded.height, AvatarCropService.outputSize);
  });

  testWidgets('bytes rusak menampilkan pesan kesalahan, Simpan nonaktif', (
    tester,
  ) async {
    await _openCropPage(tester, Uint8List.fromList([0, 1, 2, 3, 4, 5]));

    expect(find.text(AppStrings.avatarCropDecodeError), findsOneWidget);

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, AppStrings.avatarCropSave),
    );
    expect(saveButton.onPressed, isNull);
  });
}
