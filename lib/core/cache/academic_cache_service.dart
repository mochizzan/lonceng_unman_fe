import 'dart:convert';
import 'dart:developer' as developer;
import 'package:hive_ce/hive.dart';

/// Manages 4 separate Hive boxes for academic data caching.
///
/// Box structure:
/// - `credentials_box`: NPM + password (plaintext JSON)
/// - `krs_box`: KRS response data
/// - `khs_box`: KHS response data (single semester)
/// - `khs_list_box`: KHS list (all semesters)
///
/// Each box stores data as JSON strings for simplicity.
/// Data is keyed by NPM to support multiple users.
class AcademicCacheService {
  static const _credentialsBox = 'credentials_box';
  static const _krsBox = 'krs_box';
  static const _khsBox = 'khs_box';
  static const _khsListBox = 'khs_list_box';

  late Box<String> _credentials;
  late Box<String> _krs;
  late Box<String> _khs;
  late Box<String> _khsList;

  bool _initialized = false;

  /// Initialize all Hive boxes. Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _credentials = await Hive.openBox<String>(_credentialsBox);
      _krs = await Hive.openBox<String>(_krsBox);
      _khs = await Hive.openBox<String>(_khsBox);
      _khsList = await Hive.openBox<String>(_khsListBox);
      _initialized = true;
      developer.log('AcademicCacheService initialized', name: 'AcademicCache');
    } catch (e) {
      developer.log(
        'AcademicCacheService init failed: $e',
        name: 'AcademicCache',
      );
      // Try corruption recovery
      try {
        await Hive.deleteBoxFromDisk(_credentialsBox);
        await Hive.deleteBoxFromDisk(_krsBox);
        await Hive.deleteBoxFromDisk(_khsBox);
        await Hive.deleteBoxFromDisk(_khsListBox);

        _credentials = await Hive.openBox<String>(_credentialsBox);
        _krs = await Hive.openBox<String>(_krsBox);
        _khs = await Hive.openBox<String>(_khsBox);
        _khsList = await Hive.openBox<String>(_khsListBox);
        _initialized = true;
        developer.log(
          'AcademicCacheService recovered from corruption',
          name: 'AcademicCache',
        );
      } catch (e2) {
        developer.log(
          'AcademicCacheService recovery failed: $e2',
          name: 'AcademicCache',
        );
        rethrow;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CREDENTIALS (NPM + Password)
  // ═══════════════════════════════════════════════════════════════════════

  static const _npmKey = 'npm';
  static const _passwordKey = 'password';

  /// Save credentials (NPM + password).
  Future<void> saveCredentials({
    required String npm,
    required String password,
  }) async {
    await _credentials.put(_npmKey, npm);
    await _credentials.put(_passwordKey, password);
  }

  /// Load credentials. Returns null if not found.
  Future<Map<String, String>?> loadCredentials() async {
    final npm = _credentials.get(_npmKey);
    final password = _credentials.get(_passwordKey);
    if (npm == null || password == null) return null;
    return {'npm': npm, 'password': password};
  }

  /// Clear credentials.
  Future<void> clearCredentials() async {
    await _credentials.clear();
  }

  /// Check if credentials exist.
  bool hasCredentials() {
    return _credentials.get(_npmKey) != null &&
        _credentials.get(_passwordKey) != null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // KRS DATA
  // ═══════════════════════════════════════════════════════════════════════

  /// Save KRS response data.
  Future<void> saveKrsData({
    required String npm,
    required Map<String, dynamic> data,
  }) async {
    await _krs.put(npm, jsonEncode(data));
  }

  /// Load KRS data. Returns null if not cached.
  Future<Map<String, dynamic>?> loadKrsData({required String npm}) async {
    final raw = _krs.get(npm);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Failed to decode KRS cache: $e', name: 'AcademicCache');
      return null;
    }
  }

  /// Check if KRS data exists for given NPM.
  bool hasKrsData({required String npm}) {
    return _krs.get(npm) != null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // KHS DATA (single semester)
  // ═══════════════════════════════════════════════════════════════════════

  /// Save KHS response data.
  Future<void> saveKhsData({
    required String npm,
    required Map<String, dynamic> data,
  }) async {
    await _khs.put(npm, jsonEncode(data));
  }

  /// Load KHS data. Returns null if not cached.
  Future<Map<String, dynamic>?> loadKhsData({required String npm}) async {
    final raw = _khs.get(npm);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Failed to decode KHS cache: $e', name: 'AcademicCache');
      return null;
    }
  }

  /// Check if KHS data exists for given NPM.
  bool hasKhsData({required String npm}) {
    return _khs.get(npm) != null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // KHS LIST (all semesters)
  // ═══════════════════════════════════════════════════════════════════════

  /// Save KHS list data.
  Future<void> saveKhsList({
    required String npm,
    required List<dynamic> data,
  }) async {
    await _khsList.put(npm, jsonEncode(data));
  }

  /// Load KHS list. Returns null if not cached.
  Future<List<dynamic>?> loadKhsList({required String npm}) async {
    final raw = _khsList.get(npm);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (e) {
      developer.log(
        'Failed to decode KHS list cache: $e',
        name: 'AcademicCache',
      );
      return null;
    }
  }

  /// Check if KHS list exists for given NPM.
  bool hasKhsList({required String npm}) {
    return _khsList.get(npm) != null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEAR ALL
  // ═══════════════════════════════════════════════════════════════════════

  /// Clear all cached data (credentials + KRS + KHS).
  Future<void> clearAll() async {
    await _credentials.clear();
    await _krs.clear();
    await _khs.clear();
    await _khsList.clear();
    developer.log('All academic cache cleared', name: 'AcademicCache');
  }
}
