// profile/data/services - Avatar Crop Service
//
// Logika crop avatar tanpa package pihak ketiga: geometri crop dihitung dari
// `Matrix4` milik InteractiveViewer, lalu hasilnya digambar ulang memakai
// `dart:ui` menjadi PNG 256x256 berbentuk lingkaran.
//
// Tata letak yang diasumsikan (lihat AvatarCropPage):
//   child InteractiveViewer berukuran displaySize = imageSize * coverScale,
//   dengan coverScale = max(side/imgW, side/imgH). Artinya child selalu
//   >= viewport di kedua sumbu dan lebih besar di salah satunya, sehingga
//   user bisa menggeser sejak skala 1 tanpa harus zoom lebih dulu.
//
// Pemetaan koordinat:
//   piksel gambar --(* coverScale)--> child --(Matrix4)--> viewport
// Crop adalah kebalikannya: ambil kotak viewport [0, side]^2, petakan mundur
// ke child, lalu bagi coverScale untuk mendapat piksel gambar asli.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

abstract final class AvatarCropService {
  /// Sisi PNG hasil crop, dalam piksel.
  static const int outputSize = 256;

  /// Sisi terpanjang maksimum saat decode. Gambar yang lebih besar akan
  /// diperkecil menjaga aspect ratio untuk mencegah OOM; gambar yang sudah
  /// di bawah batas tidak diperbesar.
  static const int decodeMaxSide = 1024;

  /// Skala yang membuat [imageSize] menutupi kotak berukuran [viewportSide].
  static double coverScale({
    required Size imageSize,
    required double viewportSide,
  }) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return 1;
    return math.max(
      viewportSide / imageSize.width,
      viewportSide / imageSize.height,
    );
  }

  /// Ukuran child InteractiveViewer: gambar yang sudah diskalakan agar
  /// menutupi viewport.
  static Size displaySize({
    required Size imageSize,
    required double viewportSide,
  }) {
    final scale = coverScale(imageSize: imageSize, viewportSide: viewportSide);
    return Size(imageSize.width * scale, imageSize.height * scale);
  }

  /// Transform awal yang memposisikan child di tengah viewport.
  ///
  /// Tanpa ini InteractiveViewer akan menampilkan pojok kiri-atas gambar.
  /// Ini hanya titik AWAL — user tetap bebas menggeser ke mana pun.
  static Matrix4 initialTransform({
    required Size imageSize,
    required double viewportSide,
  }) {
    final display = displaySize(
      imageSize: imageSize,
      viewportSide: viewportSide,
    );
    final dx = -(display.width - viewportSide) / 2;
    final dy = -(display.height - viewportSide) / 2;
    return Matrix4.identity()..translateByDouble(dx, dy, 0, 1);
  }

  /// Menghitung area sumber (dalam piksel gambar asli) yang sedang terlihat
  /// di dalam viewport crop.
  ///
  /// [imageSize]    ukuran gambar asli dalam piksel.
  /// [viewportSide] sisi viewport crop (kotak) dalam logical pixel.
  /// [transform]    nilai TransformationController InteractiveViewer, yang
  ///                memetakan koordinat child ke koordinat viewport.
  ///
  /// Hasilnya selalu kotak dan selalu di dalam batas gambar, sehingga posisi
  /// crop mengikuti geseran/zoom user — bukan center otomatis.
  static Rect computeSourceRect({
    required Size imageSize,
    required double viewportSide,
    required Matrix4 transform,
  }) {
    final imgW = imageSize.width;
    final imgH = imageSize.height;
    if (imgW <= 0 || imgH <= 0 || viewportSide <= 0) return Rect.zero;

    final rawScale = transform.getMaxScaleOnAxis();
    final scale = rawScale <= 0 ? 1.0 : rawScale;
    final translation = transform.getTranslation();

    final cover = coverScale(imageSize: imageSize, viewportSide: viewportSide);
    if (cover <= 0) return Rect.zero;

    // viewport -> child -> piksel gambar
    final maxSide = math.min(imgW, imgH);
    final side = (viewportSide / scale / cover).clamp(1.0, maxSide);
    final left = (-translation.x / scale / cover).clamp(0.0, imgW - side);
    final top = (-translation.y / scale / cover).clamp(0.0, imgH - side);

    return Rect.fromLTWH(left, top, side, side);
  }

  /// Menggambar ulang [image] pada area [sourceRect] menjadi PNG
  /// [outputSize] x [outputSize] dengan mask lingkaran (sudut transparan).
  ///
  /// Mengembalikan null bila encoding PNG gagal.
  static Future<Uint8List?> renderCircularPng({
    required ui.Image image,
    required Rect sourceRect,
  }) async {
    if (sourceRect.isEmpty) return null;

    final side = outputSize.toDouble();
    final destRect = Rect.fromLTWH(0, 0, side, side);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, destRect);

    // Mask lingkaran — inti permintaan "crop circular".
    canvas.clipPath(Path()..addOval(destRect), doAntiAlias: true);
    canvas.drawImageRect(
      image,
      sourceRect,
      destRect,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    ui.Image? rendered;
    try {
      rendered = await picture.toImage(outputSize, outputSize);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      return data.buffer.asUint8List();
    } finally {
      rendered?.dispose();
      picture.dispose();
    }
  }

  /// Mendekode bytes gambar menjadi [ui.Image].
  ///
  /// Sisi terpanjang dibatasi [decodeMaxSide] piksel untuk mencegah OOM pada
  /// gambar berukuran besar. Aspect ratio dipertahankan. Gambar yang sudah
  /// lebih kecil dari batas tidak diperbesar.
  static Future<ui.Image> decode(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final origW = descriptor.width;
      final origH = descriptor.height;
      if (origW <= 0 || origH <= 0) {
        throw const FormatException('dimensi gambar tidak valid');
      }

      final int targetW;
      final int targetH;
      if (origW <= decodeMaxSide && origH <= decodeMaxSide) {
        // Sudah di bawah batas: pakai dimensi asli, jangan diperbesar.
        targetW = origW;
        targetH = origH;
      } else {
        // Sisi terpanjang diperkecil ke decodeMaxSide, sisi lain mengikuti
        // aspect ratio.
        final ratio = origW / origH;
        if (ratio >= 1) {
          targetW = decodeMaxSide;
          targetH = (decodeMaxSide / ratio).round();
        } else {
          targetH = decodeMaxSide;
          targetW = (decodeMaxSide * ratio).round();
        }
      }

      codec = await descriptor.instantiateCodec(
        targetWidth: targetW,
        targetHeight: targetH,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
