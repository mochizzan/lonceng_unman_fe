// core/cache - Avatar Cache Service
//
// Menyimpan foto profil (avatar) lokal per mahasiswa di Hive box `avatar`.
//
// Box ini SENGAJA terpisah dari box `credentials` / `academic` milik
// [AcademicCacheService] agar TIDAK ikut terhapus saat logout: avatar
// bertahan lintas sesi login dan setiap NPM punya avatarnya sendiri.
//
// Key   : NPM mahasiswa
// Value : bytes PNG hasil crop (Uint8List, 256x256)

import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';

class AvatarCacheService {
  /// Nama Hive box khusus avatar — tidak dibersihkan oleh logout.
  static const String boxName = 'avatar';

  late Box<dynamic> _box;
  bool _initialized = false;

  /// Membuka box `avatar`. Aman dipanggil berulang kali.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _box = await Hive.openBox<dynamic>(boxName);
      _initialized = true;
    } catch (e) {
      developer.log(
        'Box avatar gagal dibuka, melakukan pemulihan korupsi: $e',
        name: 'AvatarCache',
      );
      await Hive.deleteBoxFromDisk(boxName);
      _box = await Hive.openBox<dynamic>(boxName);
      _initialized = true;
    }
  }

  /// Memastikan box siap dipakai, termasuk setelah hot restart yang
  /// membuat box tertutup tanpa main() dijalankan ulang.
  Future<void> _ensureReady() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    if (!_box.isOpen) {
      developer.log(
        'Box avatar tertutup setelah restart, membuka ulang',
        name: 'AvatarCache',
      );
      try {
        _box = await Hive.openBox<dynamic>(boxName);
      } catch (e) {
        developer.log(
          'Gagal membuka ulang box avatar: $e',
          name: 'AvatarCache',
        );
        await Hive.deleteBoxFromDisk(boxName);
        _box = await Hive.openBox<dynamic>(boxName);
      }
    }
  }

  /// Menyimpan bytes PNG avatar untuk [npm].
  Future<void> saveAvatar({
    required String npm,
    required Uint8List bytes,
  }) async {
    await _ensureReady();
    await _box.put(npm, bytes);
  }

  /// Mengambil bytes PNG avatar milik [npm], atau null bila belum ada.
  Future<Uint8List?> loadAvatar(String npm) async {
    await _ensureReady();
    final raw = _box.get(npm);
    if (raw == null) return null;
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    return null;
  }

  /// Menghapus avatar milik [npm].
  Future<void> deleteAvatar(String npm) async {
    await _ensureReady();
    await _box.delete(npm);
  }

  /// True bila [npm] sudah punya avatar tersimpan.
  bool hasAvatar(String npm) {
    if (!_initialized || !_box.isOpen) return false;
    return _box.containsKey(npm);
  }
}
