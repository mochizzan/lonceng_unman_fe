// bio_cache_service.dart
//
// Manages a single Hive box for bio data caching.
// Each user is keyed by NPM (e.g. 'bio_12345678').
// Follows the same pattern as AcademicCacheService.

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:hive_ce/hive.dart';

/// Custom exception for bio cache corruption.
class BioCacheCorruptedException implements Exception {
  final String message;
  const BioCacheCorruptedException(this.message);

  @override
  String toString() => 'BioCacheCorruptedException: $message';
}

/// Manages the Hive box for student bio data.
///
/// Box structure:
/// - `bio`: NPM-keyed bio strings per user
///
/// Each user is keyed by `'bio_$npm'`. Bio is stored as a simple String
/// or null (when deleted).
class BioCacheService {
  // Box name
  static const _bioBox = 'bioBox';

  // Box instance
  late Box<dynamic> _bio;

  bool _initialized = false;
  bool _corrupted = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _bio = await Hive.openBox<dynamic>(_bioBox);
      _initialized = true;
    } catch (e) {
      debugPrint('[BioCache] Bio box corrupted, recovering: $e');
      // Corruption recovery — delete and recreate
      await Hive.deleteBoxFromDisk(_bioBox);
      _bio = await Hive.openBox<dynamic>(_bioBox);
      _initialized = true;
      _corrupted = true;
    }
  }

  /// Returns true if corruption was detected during initialization.
  bool get wasCorrupted => _corrupted;

  /// Clears the corruption flag after it has been handled.
  void clearCorruptionFlag() {
    _corrupted = false;
  }

  /// Ensures Hive box is open and accessible.
  ///
  /// After a hot restart, [initialize] is not re-called (main() doesn't
  /// re-execute), but the box may need re-opening. This method
  /// re-opens it safely if it is closed or inaccessible.
  Future<void> _ensureReady() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    // Verify box is actually open; re-open if needed.
    if (!_bio.isOpen) {
      debugPrint('[BioCache] Hive bio box closed after restart, re-opening');
      try {
        _bio = await Hive.openBox<dynamic>(_bioBox);
      } catch (e) {
        debugPrint('[BioCache] Failed to re-open Hive bio box: $e');
        // Corruption recovery
        await Hive.deleteBoxFromDisk(_bioBox);
        _bio = await Hive.openBox<dynamic>(_bioBox);
        _corrupted = true;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BIO CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Saves bio for a given NPM.
  Future<void> saveBio({required String npm, required String bio}) async {
    await _ensureReady();
    final key = 'bio_$npm';
    await _bio.put(key, bio);
  }

  /// Loads bio for a given NPM. Returns null if no bio exists.
  Future<String?> loadBio({required String npm}) async {
    await _ensureReady();
    final key = 'bio_$npm';
    final raw = _bio.get(key);
    if (raw == null) return null;
    return raw as String;
  }

  /// Deletes bio for a given NPM (sets to null).
  Future<void> deleteBio({required String npm}) async {
    await _ensureReady();
    final key = 'bio_$npm';
    await _bio.delete(key);
  }

  /// Clears all bio data.
  Future<void> clearAll() async {
    await _ensureReady();
    await _bio.clear();
  }
}
