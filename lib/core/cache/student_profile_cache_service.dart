// student_profile_cache_service.dart
//
// Manages Hive box for student profile caching.
// Each user's profile is keyed by NPM.
// Follows the same pattern as AcademicCacheService.

import 'dart:developer' as developer;

import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/core/utils/map_cast.dart';

/// Mengelola Hive box untuk caching data profil mahasiswa.
///
/// Box structure:
/// - `studentProfile`: data profil per NPM
class StudentProfileCacheService {
  // Nama box Hive
  static const _boxName = 'studentProfile';

  // Instance box (Box<dynamic> karena Hive CE tidak bisa buka box typed Map)
  late Box<dynamic> _box;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
      _initialized = true;
    } catch (e) {
      // Recovery jika box corrupt
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<dynamic>(_boxName);
      _initialized = true;
    }
  }

  /// Memastikan box Hive terbuka dan bisa diakses.
  ///
  /// Setelah hot restart, [initialize] tidak dipanggil ulang (main() tidak
  /// dijalankan ulang), tapi box mungkin perlu dibuka ulang. Metode ini
  /// membuka ulang box dengan aman jika box tertutup atau tidak bisa diakses.
  Future<void> _ensureReady() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    // Verifikasi box benar-benar terbuka; buka ulang jika perlu.
    if (!_box.isOpen) {
      developer.log(
        'Hive box studentProfile closed after restart, re-opening',
        name: 'StudentProfileCache',
      );
      try {
        _box = await Hive.openBox<dynamic>(_boxName);
      } catch (e) {
        developer.log(
          'Failed to re-open Hive box: $e',
          name: 'StudentProfileCache',
        );
        // Recovery jika box corrupt
        await Hive.deleteBoxFromDisk(_boxName);
        _box = await Hive.openBox<dynamic>(_boxName);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════════════════

  /// Menyimpan data profil mahasiswa ke cache.
  ///
  /// [npm] digunakan sebagai key. [profileData] adalah Map yang berisi
  /// seluruh data profil dari API.
  Future<void> saveProfile({
    required String npm,
    required Map<String, dynamic> profileData,
  }) async {
    await _ensureReady();
    await _box.put(npm, profileData);
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════

  /// Memuat data profil mahasiswa dari cache.
  ///
  /// Mengembalikan `null` jika data tidak ditemukan.
  Future<Map<String, dynamic>?> loadProfile({required String npm}) async {
    await _ensureReady();
    final raw = _box.get(npm);
    if (raw == null) return null;
    return asStringMap(raw);
  }

  // ═══════════════════════════════════════════════════════════════
  // HAS
  // ═══════════════════════════════════════════════════════════════

  /// Mengecek apakah data profil untuk [npm] tersedia di cache.
  bool hasProfile({required String npm}) {
    if (!_initialized || !_box.isOpen) return false;
    return _box.containsKey(npm);
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════════

  /// Menghapus data profil untuk [npm] dari cache.
  Future<void> clearProfile({required String npm}) async {
    await _ensureReady();
    await _box.delete(npm);
  }

  /// Menghapus semua data profil dari cache.
  Future<void> clearAll() async {
    await _ensureReady();
    await _box.clear();
  }
}
