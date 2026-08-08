// Test geometri crop avatar.
//
// Membuktikan bahwa area crop mengikuti geseran/zoom user, bukan selalu
// center, dan hasil render selalu PNG 256x256.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_crop_service.dart';

/// Membuat gambar sintetis [w]x[h]: separuh kiri merah, separuh kanan biru.
Future<ui.Image> _makeImage(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w / 2, h.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    Rect.fromLTWH(w / 2, 0, w / 2, h.toDouble()),
    Paint()..color = const Color(0xFF0000FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('displaySize', () {
    test('gambar landscape diskalakan agar tinggi pas viewport', () {
      final display = AvatarCropService.displaySize(
        imageSize: const Size(800, 400),
        viewportSide: 300,
      );
      // coverScale = max(300/800, 300/400) = 0.75
      expect(display.width, closeTo(600, 0.001));
      expect(display.height, closeTo(300, 0.001));
    });

    test('child selalu >= viewport di kedua sumbu', () {
      final display = AvatarCropService.displaySize(
        imageSize: const Size(400, 900),
        viewportSide: 300,
      );
      expect(display.width, greaterThanOrEqualTo(300));
      expect(display.height, greaterThanOrEqualTo(300));
    });
  });

  group('initialTransform', () {
    test('memusatkan gambar landscape secara horizontal', () {
      final transform = AvatarCropService.initialTransform(
        imageSize: const Size(800, 400),
        viewportSide: 300,
      );
      final t = transform.getTranslation();
      // display 600x300 di viewport 300 => geser -150 pada sumbu x
      expect(t.x, closeTo(-150, 0.001));
      expect(t.y, closeTo(0, 0.001));
    });
  });

  group('computeSourceRect', () {
    const imageSize = Size(800, 400);
    const side = 300.0;

    test('transform awal menghasilkan crop tepat di tengah', () {
      final rect = AvatarCropService.computeSourceRect(
        imageSize: imageSize,
        viewportSide: side,
        transform: AvatarCropService.initialTransform(
          imageSize: imageSize,
          viewportSide: side,
        ),
      );
      // Sisi crop = 400 (tinggi penuh), center horizontal => left = 200
      expect(rect.width, closeTo(400, 0.001));
      expect(rect.height, closeTo(400, 0.001));
      expect(rect.left, closeTo(200, 0.001));
      expect(rect.top, closeTo(0, 0.001));
    });

    test('geser ke kiri memindahkan crop ke sisi kanan gambar', () {
      final centered = AvatarCropService.initialTransform(
        imageSize: imageSize,
        viewportSide: side,
      );
      final centeredRect = AvatarCropService.computeSourceRect(
        imageSize: imageSize,
        viewportSide: side,
        transform: centered,
      );

      // Menggeser child 75px lagi ke kiri = melihat area lebih ke kanan.
      final panned = centered.clone()..translateByDouble(-100, 0, 0, 1);
      final pannedRect = AvatarCropService.computeSourceRect(
        imageSize: imageSize,
        viewportSide: side,
        transform: panned,
      );

      expect(
        pannedRect.left,
        greaterThan(centeredRect.left),
        reason: 'crop harus bergeser ke kanan mengikuti geseran user',
      );
      expect(pannedRect.width, closeTo(centeredRect.width, 0.001));
    });

    test('zoom memperkecil area sumber', () {
      final base = AvatarCropService.initialTransform(
        imageSize: imageSize,
        viewportSide: side,
      );
      final baseRect = AvatarCropService.computeSourceRect(
        imageSize: imageSize,
        viewportSide: side,
        transform: base,
      );

      final zoomed = Matrix4.identity()
        ..scaleByDouble(2, 2, 1, 1)
        ..translateByDouble(-200, -100, 0, 1);
      final zoomedRect = AvatarCropService.computeSourceRect(
        imageSize: imageSize,
        viewportSide: side,
        transform: zoomed,
      );

      expect(zoomedRect.width, lessThan(baseRect.width));
      expect(zoomedRect.width, closeTo(baseRect.width / 2, 0.001));
    });

    test('crop tidak pernah keluar batas gambar', () {
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

    test('ukuran gambar nol menghasilkan Rect.zero', () {
      expect(
        AvatarCropService.computeSourceRect(
          imageSize: Size.zero,
          viewportSide: side,
          transform: Matrix4.identity(),
        ),
        Rect.zero,
      );
    });
  });

  group('renderCircularPng', () {
    test('menghasilkan PNG 256x256', () async {
      final image = await _makeImage(800, 400);
      addTearDown(image.dispose);

      final png = await AvatarCropService.renderCircularPng(
        image: image,
        sourceRect: const Rect.fromLTWH(200, 0, 400, 400),
      );

      expect(png, isNotNull);
      expect(png!.isNotEmpty, isTrue);

      final decoded = await AvatarCropService.decode(png);
      addTearDown(decoded.dispose);
      expect(decoded.width, AvatarCropService.outputSize);
      expect(decoded.height, AvatarCropService.outputSize);
    });

    test('mengambil area sumber yang diminta, bukan center', () async {
      final image = await _makeImage(800, 400);
      addTearDown(image.dispose);

      // Ambil hanya sisi KIRI (merah). Center gambar berada di perbatasan
      // merah/biru, jadi hasil merah membuktikan crop mengikuti sourceRect.
      final png = await AvatarCropService.renderCircularPng(
        image: image,
        sourceRect: const Rect.fromLTWH(0, 0, 400, 400),
      );
      expect(png, isNotNull);

      final decoded = await AvatarCropService.decode(png!);
      addTearDown(decoded.dispose);
      final data = await decoded.toByteData();
      expect(data, isNotNull);

      // Piksel tengah (128,128) — pasti di dalam lingkaran.
      final bytes = data!.buffer.asUint8List();
      const offset = (128 * AvatarCropService.outputSize + 128) * 4;
      expect(bytes[offset], greaterThan(200), reason: 'kanal merah tinggi');
      expect(bytes[offset + 2], lessThan(60), reason: 'kanal biru rendah');
    });

    test('sudut hasil transparan karena mask lingkaran', () async {
      final image = await _makeImage(400, 400);
      addTearDown(image.dispose);

      final png = await AvatarCropService.renderCircularPng(
        image: image,
        sourceRect: const Rect.fromLTWH(0, 0, 400, 400),
      );
      final decoded = await AvatarCropService.decode(png!);
      addTearDown(decoded.dispose);

      final data = await decoded.toByteData();
      final bytes = data!.buffer.asUint8List();
      // Piksel (0,0) berada di luar lingkaran => alpha 0.
      expect(bytes[3], 0);
    });

    test('sourceRect kosong mengembalikan null', () async {
      final image = await _makeImage(100, 100);
      addTearDown(image.dispose);

      expect(
        await AvatarCropService.renderCircularPng(
          image: image,
          sourceRect: Rect.zero,
        ),
        isNull,
      );
    });
  });

  group('decode', () {
    test('membaca kembali PNG yang dihasilkan', () async {
      final image = await _makeImage(64, 64);
      addTearDown(image.dispose);

      final png = await AvatarCropService.renderCircularPng(
        image: image,
        sourceRect: const Rect.fromLTWH(0, 0, 64, 64),
      );
      final decoded = await AvatarCropService.decode(png as Uint8List);
      addTearDown(decoded.dispose);

      expect(decoded.width, AvatarCropService.outputSize);
    });
  });
}
