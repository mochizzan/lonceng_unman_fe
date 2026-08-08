// profile/data/services - Avatar Picker Service
//
// Pembungkus tipis `image_picker` untuk mengambil satu gambar dari galeri.
// Sengaja hanya mengembalikan bytes agar layer presentation tidak perlu
// tahu soal XFile maupun path file sementara.

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Domain exception: izin galeri ditolak.
///
/// Pemanggil sebaiknya memetakan ke [AppStrings.avatarPermissionDenied].
///
/// Catatan penting: di Android modern (Photo Picker) izin tidak diminta sama
/// sekali, sehingga jalur permission-denied praktis hanya terjadi di iOS
/// dan Android lama. Ini batasan yang diketahui, bukan bug.
class AvatarPermissionDeniedException implements Exception {}

/// Domain exception: kegagalan lain saat membuka galeri (bukan izin).
///
/// Pemanggil sebaiknya memetakan ke [AppStrings.avatarPickError].
class AvatarPickFailedException implements Exception {}

class AvatarPickerService {
  AvatarPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Batas sisi terpanjang gambar sumber sebelum masuk halaman crop.
  /// Menjaga penggunaan memori tetap wajar tanpa mengorbankan ketajaman
  /// hasil crop 256x256.
  static const double _maxSourceSide = 2048;

  /// Membuka galeri. Mengembalikan bytes gambar terpilih,
  /// atau null bila user membatalkan.
  ///
  /// Melempar [AvatarPermissionDeniedException] bila platform menolak izin
  /// galeri (iOS/Android lama), atau [AvatarPickFailedException] untuk
  /// kegagalan lain. Hasil `null` dari `pickImage` berarti user membatalkan
  /// dan TIDAK melempar exception.
  Future<Uint8List?> pickFromGallery() async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxSourceSide,
        maxHeight: _maxSourceSide,
      );
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      const deniedCodes = <String>[
        'photo_access_denied',
        'camera_access_denied',
        'access_denied',
        'permission',
      ];
      final isDenied = deniedCodes.any(code.contains);
      if (isDenied) {
        throw AvatarPermissionDeniedException();
      }
      throw AvatarPickFailedException();
    }
    if (file == null) return null;
    return file.readAsBytes();
  }
}
