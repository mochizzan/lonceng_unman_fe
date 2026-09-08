import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  const srcPath = 'assets/images/app_logo.png';
  final srcBytes = await File(srcPath).readAsBytes();
  final src = img.decodePng(srcBytes);
  if (src == null) {
    stderr.writeln('Failed to decode $srcPath');
    exit(2);
  }
  print('Source: ${src.width}x${src.height}');

  // Helper: resize + write png
  Future<void> writePng(String outPath, int size, {int? padForMaskable}) async {
    img.Image out;
    if (padForMaskable != null) {
      // maskable: place logo centered with padding on #FFF8F2 background
      // padForMaskable is the total size, logo is 80% of it
      final bg = img.Image(width: size, height: size);
      // #FFF8F2 = 255,248,242
      img.fill(bg, color: img.ColorRgb8(255, 248, 242));
      final logoSize = (size * 0.8).round();
      final resized = img.copyResize(
        src,
        width: logoSize,
        height: logoSize,
        interpolation: img.Interpolation.cubic,
      );
      final offset = (size - logoSize) ~/ 2;
      img.compositeImage(bg, resized, dstX: offset, dstY: offset);
      out = bg;
    } else {
      out = img.copyResize(
        src,
        width: size,
        height: size,
        interpolation: img.Interpolation.cubic,
      );
    }
    final dir = File(outPath).parent;
    if (!dir.existsSync()) dir.createSync(recursive: true);
    await File(outPath).writeAsBytes(img.encodePng(out));
    print('  wrote $outPath ${size}x$size');
  }

  // Android mipmap
  final androidSizes = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };
  print('\nAndroid mipmap:');
  for (final e in androidSizes.entries) {
    await writePng(e.key, e.value);
  }

  // Web
  print('\nWeb:');
  await writePng('web/favicon.png', 32);
  await writePng('web/icons/Icon-192.png', 192);
  await writePng('web/icons/Icon-512.png', 512);
  await writePng('web/icons/Icon-maskable-192.png', 192, padForMaskable: 192);
  await writePng('web/icons/Icon-maskable-512.png', 512, padForMaskable: 512);

  // iOS AppIcon.appiconset
  print('\niOS:');
  final iosMap = {
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png':
        167,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
        1024,
  };
  for (final e in iosMap.entries) {
    await writePng(e.key, e.value);
  }

  // Windows ICO: image.encodeIco takes single Image (256); encoder handles frames.
  print('\nWindows ICO:');
  try {
    final icoImg = img.copyResize(
      src,
      width: 256,
      height: 256,
      interpolation: img.Interpolation.cubic,
    );
    final icoBytes = img.encodeIco(icoImg);
    await File('windows/runner/resources/app_icon.ico').writeAsBytes(icoBytes);
    print(
      '  wrote windows/runner/resources/app_icon.ico 256 ${icoBytes.length} bytes',
    );
  } catch (e, st) {
    print('  ICO encode failed: $e');
    print(st);
    // fallback: write 256 png as ico (let Windows use png)
    await writePng('windows/runner/resources/app_icon.png', 256);
    print('  fallback wrote app_icon.png');
  }

  print('\nDone.');
}
