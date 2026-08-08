// profile/data/services - Avatar Picker Service
//
// Pembungkus tipis `image_picker` untuk mengambil satu gambar dari galeri.
// Sengaja hanya mengembalikan bytes agar layer presentation tidak perlu
// tahu soal XFile maupun path file sementara.

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

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
  Future<Uint8List?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxSourceSide,
      maxHeight: _maxSourceSide,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
