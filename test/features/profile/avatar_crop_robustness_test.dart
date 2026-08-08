// Test ketahanan avatar crop.
//
// Menutup celah-celah yang ditemukan saat audit:
//   #7 — decode membatasi sisi terpanjang (cegah OOM) tanpa memperbesar
//        gambar kecil
//   #3 — tombol Simpan tidak memicu render kedua bila ditekan dua kali
//   #6 — bytes rusak tetap memunculkan pesan kesalahan (regresi)
//   #9 — computeSourceRect ter-clamp di dalam batas gambar (regresi)
//
// Catatan teknis: seluruh operasi `dart:ui` membutuhkan async NYATA.
// `pumpAndSettle` dihindari selama indikator loading tampil karena
// animasinya tidak pernah berhenti.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_crop_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/avatar_crop_page.dart';

/// PNG sintetis [w]x[h] berwarna solid.
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

int _resultCount = 0;
Uint8List? _result;

Future<void> _openCropPage(WidgetTester tester, Uint8List bytes) async {
  _result = null;
  _resultCount = 0;

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
                _resultCount++;
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('buka'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await _flush(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ────────────────────────────────────────────────────────────────────────
  // Celah #7 — batas decode 1024 (cegah OOM)
  // ────────────────────────────────────────────────────────────────────────
  group('decode membatasi sisi terpanjang', () {
    test(
      'PNG 3000x2000 dipersempit, sisi terpanjang <= 1024, ratio terjaga',
      () async {
        final png = await _makePng(3000, 2000);
        final decoded = await AvatarCropService.decode(png);
        addTearDown(decoded.dispose);

        final longest = math.max(decoded.width, decoded.height);
        expect(
          longest,
          lessThanOrEqualTo(AvatarCropService.decodeMaxSide),
          reason: 'sisi terpanjang harus <= decodeMaxSide',
        );

        // Ratio asli 3000/2000 = 1.5 — harus dipertahankan (toleransi ~0.02).
        final ratio = decoded.width / decoded.height;
        expect(
          ratio,
          closeTo(1.5, 0.02),
          reason: 'aspect ratio harus dipertahankan',
        );
      },
    );

    test('PNG kecil 200x150 TIDAK diperbesar', () async {
      final png = await _makePng(200, 150);
      final decoded = await AvatarCropService.decode(png);
      addTearDown(decoded.dispose);

      expect(decoded.width, 200, reason: 'gambar kecil tidak boleh diperbesar');
      expect(
        decoded.height,
        150,
        reason: 'gambar kecil tidak boleh diperbesar',
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Celah #3 — Simpan ditekan dua kali
  // ────────────────────────────────────────────────────────────────────────
  testWidgets('menekan Simpan dua kali hanya menghasilkan SATU pop', (
    tester,
  ) async {
    final png = await tester.runAsync(() => _makePng(400, 300));
    await _openCropPage(tester, png!);

    // Ketukan pertama.
    await tester.tap(find.text(AppStrings.avatarCropSave));
    await tester.pump();

    // Tombol Simpan harus nonaktif (onPressed null) setelah ketukan pertama.
    // Catatan: setelah _saving = true, child tombol berubah menjadi spinner
    // (tanpa teks), sehingga kita cari berdasarkan tipe, bukan teks.
    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      saveButton.onPressed,
      isNull,
      reason: 'tombol Simpan harus nonaktif selama proses render',
    );

    // Ketukan kedua — tidak ada efek karena tombol sudah nonaktif.
    await tester.tap(find.byType(FilledButton));

    // Selesaikan render.
    await _flush(tester, rounds: 8);
    await tester.pump(const Duration(milliseconds: 400));
    await _flush(tester);

    expect(_resultCount, 1, reason: 'hanya boleh ada SATU hasil pop');
    expect(_result, isNotNull);
  });

  // ────────────────────────────────────────────────────────────────────────
  // Celah #6 (regresi) — bytes rusak
  // ────────────────────────────────────────────────────────────────────────
  testWidgets('bytes rusak memunculkan pesan error, Simpan nonaktif', (
    tester,
  ) async {
    await _openCropPage(tester, Uint8List.fromList([0, 1, 2, 3, 4, 5]));

    expect(find.text(AppStrings.avatarCropDecodeError), findsOneWidget);

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, AppStrings.avatarCropSave),
    );
    expect(saveButton.onPressed, isNull);
  });

  // ────────────────────────────────────────────────────────────────────────
  // Celah #9 (regresi) — computeSourceRect ter-clamp
  // ────────────────────────────────────────────────────────────────────────
  test('computeSourceRect tetap ter-clamp pada zoom ekstrem', () {
    const imageSize = Size(800, 400);
    const side = 300.0;

    // Translasi ekstrem yang secara matematis melewati tepi kanan.
    final extreme = Matrix4.identity()..translateByDouble(-5000, -5000, 0, 1);
    final rect = AvatarCropService.computeSourceRect(
      imageSize: imageSize,
      viewportSide: side,
      transform: extreme,
    );

    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(imageSize.width + 0.001));
    expect(rect.bottom, lessThanOrEqualTo(imageSize.height + 0.001));
  });
}
