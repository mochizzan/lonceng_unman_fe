import 'package:flutter/foundation.dart' show debugPrint;

import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/core/utils/map_cast.dart';

/// Manages 3 Hive boxes for academic data caching.
///
/// Box structure:
/// - `credentials`: NPM + password per user
/// - `academic`: KRS, KHS list, and per-semester KHS data per user
///
/// Each user is keyed by NPM. Academic data is stored as nested Maps
/// inside a single box entry per NPM.
class AcademicCacheService {
  // Box names
  static const _credentialsBox = 'credentials';
  static const _academicBox = 'academic';

  // Box instances (Box<dynamic> because Hive CE cannot open typed Map boxes)
  late Box<dynamic> _credentials;
  late Box<dynamic> _academic;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _credentials = await Hive.openBox<dynamic>(_credentialsBox);
      _academic = await Hive.openBox<dynamic>(_academicBox);
      _initialized = true;
    } catch (e) {
      // Corruption recovery
      await Hive.deleteBoxFromDisk(_credentialsBox);
      await Hive.deleteBoxFromDisk(_academicBox);
      _credentials = await Hive.openBox<dynamic>(_credentialsBox);
      _academic = await Hive.openBox<dynamic>(_academicBox);
      _initialized = true;
    }
  }

  /// Ensures Hive boxes are open and accessible.
  ///
  /// After a hot restart, [initialize] is not re-called (main() doesn't
  /// re-execute), but the boxes may need re-opening. This method
  /// re-opens them safely if they are closed or inaccessible.
  Future<void> _ensureReady() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    // Verify boxes are actually open; re-open if needed.
    if (!_credentials.isOpen || !_academic.isOpen) {
      debugPrint('[AcademicCache] Hive boxes closed after restart, re-opening');
      try {
        _credentials = await Hive.openBox<dynamic>(_credentialsBox);
        _academic = await Hive.openBox<dynamic>(_academicBox);
      } catch (e) {
        debugPrint('[AcademicCache] Failed to re-open Hive boxes: $e');
        // Corruption recovery
        await Hive.deleteBoxFromDisk(_credentialsBox);
        await Hive.deleteBoxFromDisk(_academicBox);
        _credentials = await Hive.openBox<dynamic>(_credentialsBox);
        _academic = await Hive.openBox<dynamic>(_academicBox);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREDENTIALS
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveCredentials({
    required String npm,
    required String password,
  }) async {
    await _ensureReady();
    await _credentials.put(npm, {'npm': npm, 'password': password});
  }

  Future<Map<String, String>?> loadCredentials() async {
    await _ensureReady();
    // Get all credentials (first user for now)
    if (_credentials.isEmpty) return null;
    final data = _credentials.values.first as Map<dynamic, dynamic>;
    return {
      'npm': data['npm'] as String,
      'password': data['password'] as String,
    };
  }

  Future<Map<String, String>?> loadCredentialsByNpm(String npm) async {
    await _ensureReady();
    final raw = _credentials.get(npm);
    if (raw == null) return null;
    final data = raw as Map<dynamic, dynamic>;
    return {
      'npm': data['npm'] as String,
      'password': data['password'] as String,
    };
  }

  bool hasCredentials() {
    if (!_initialized || !_credentials.isOpen) return false;
    return _credentials.isNotEmpty;
  }

  Future<void> clearCredentials() async {
    await _ensureReady();
    await _credentials.clear();
  }

  // ═══════════════════════════════════════════════════════════════
  // ACADEMIC DATA (KRS + KHS)
  // ═══════════════════════════════════════════════════════════════

  // KRS
  Future<void> saveKrsData({
    required String npm,
    required Map<String, dynamic> data,
  }) async {
    await _ensureReady();
    final raw = _academic.get(npm);
    final existing = (raw != null
        ? Map<String, dynamic>.from(raw as Map)
        : <String, dynamic>{});
    existing['krs'] = data;
    await _academic.put(npm, existing);
  }

  Future<Map<String, dynamic>?> loadKrsData({required String npm}) async {
    await _ensureReady();
    final raw = _academic.get(npm);
    if (raw == null) return null;
    final data = raw as Map<dynamic, dynamic>;
    final krs = data['krs'];
    return krs != null ? asStringMap(krs) : null;
  }

  bool hasKrsData({required String npm}) {
    if (!_initialized || !_academic.isOpen) return false;
    final raw = _academic.get(npm);
    if (raw == null) return false;
    final data = raw as Map<dynamic, dynamic>;
    return data['krs'] != null;
  }

  // KHS LIST
  Future<void> saveKhsList({
    required String npm,
    required List<dynamic> data,
  }) async {
    await _ensureReady();
    final raw = _academic.get(npm);
    final existing = (raw != null
        ? Map<String, dynamic>.from(raw as Map)
        : <String, dynamic>{});
    existing['khsList'] = data;
    await _academic.put(npm, existing);
  }

  Future<List<dynamic>?> loadKhsList({required String npm}) async {
    await _ensureReady();
    final raw = _academic.get(npm);
    if (raw == null) return null;
    final data = raw as Map<dynamic, dynamic>;
    return data['khsList'] as List<dynamic>?;
  }

  bool hasKhsList({required String npm}) {
    if (!_initialized || !_academic.isOpen) return false;
    final raw = _academic.get(npm);
    if (raw == null) return false;
    final data = raw as Map<dynamic, dynamic>;
    return data['khsList'] != null;
  }

  // KHS DATA (per semester)
  String _khsKey(String tahunAjaran, String semester) =>
      '${tahunAjaran}_$semester';

  Future<void> saveKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
    required Map<String, dynamic> data,
  }) async {
    await _ensureReady();
    final raw = _academic.get(npm);
    final existing = (raw != null
        ? Map<String, dynamic>.from(raw as Map)
        : <String, dynamic>{});
    final khsRaw = existing['khs'];
    final khs = khsRaw != null
        ? Map<String, dynamic>.from(khsRaw as Map)
        : <String, dynamic>{};
    khs[_khsKey(tahunAjaran, semester)] = data;
    existing['khs'] = khs;
    await _academic.put(npm, existing);
  }

  Future<Map<String, dynamic>?> loadKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    await _ensureReady();
    final raw = _academic.get(npm);
    if (raw == null) return null;
    final data = raw as Map<dynamic, dynamic>;
    final khsRaw = data['khs'];
    if (khsRaw == null) return null;
    final khs = khsRaw as Map<dynamic, dynamic>;
    final result = khs[_khsKey(tahunAjaran, semester)];
    return result != null ? asStringMap(result) : null;
  }

  Future<bool> hasKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    await _ensureReady();
    final raw = _academic.get(npm);
    if (raw == null) return false;
    final data = raw as Map<dynamic, dynamic>;
    final khsRaw = data['khs'];
    if (khsRaw == null) return false;
    final khs = khsRaw as Map<dynamic, dynamic>;
    return khs.containsKey(_khsKey(tahunAjaran, semester));
  }

  // CHECK DATA EXISTS
  bool hasAcademicData({required String npm}) {
    if (!_initialized || !_academic.isOpen) return false;
    final raw = _academic.get(npm);
    if (raw == null) return false;
    final data = raw as Map<dynamic, dynamic>;
    return data.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearKrsData() async {
    await _ensureReady();
    // Clear KRS for all users
    for (final key in _academic.keys) {
      final raw = _academic.get(key);
      if (raw != null) {
        final data = Map<String, dynamic>.from(raw as Map);
        data.remove('krs');
        await _academic.put(key as String, data);
      }
    }
  }

  Future<void> clearKhsData() async {
    await _ensureReady();
    // Clear KHS for all users
    for (final key in _academic.keys) {
      final raw = _academic.get(key);
      if (raw != null) {
        final data = Map<String, dynamic>.from(raw as Map);
        data.remove('khs');
        data.remove('khsList');
        await _academic.put(key as String, data);
      }
    }
  }

  Future<void> clearAcademicData() async {
    await _ensureReady();
    await _academic.clear();
  }

  Future<void> clearAll() async {
    await _ensureReady();
    await _credentials.clear();
    await _academic.clear();
  }
}
