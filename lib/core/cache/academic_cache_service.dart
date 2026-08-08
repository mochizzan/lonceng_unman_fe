import 'package:hive_ce/hive.dart';

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

  // Box instances
  late Box<Map<String, dynamic>> _credentials;
  late Box<Map<String, dynamic>> _academic;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _credentials = await Hive.openBox<Map<String, dynamic>>(_credentialsBox);
      _academic = await Hive.openBox<Map<String, dynamic>>(_academicBox);
      _initialized = true;
    } catch (e) {
      // Corruption recovery
      await Hive.deleteBoxFromDisk(_credentialsBox);
      await Hive.deleteBoxFromDisk(_academicBox);
      _credentials = await Hive.openBox<Map<String, dynamic>>(_credentialsBox);
      _academic = await Hive.openBox<Map<String, dynamic>>(_academicBox);
      _initialized = true;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREDENTIALS
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveCredentials({
    required String npm,
    required String password,
  }) async {
    await _credentials.put(npm, {'npm': npm, 'password': password});
  }

  Future<Map<String, String>?> loadCredentials() async {
    // Get all credentials (first user for now)
    if (_credentials.isEmpty) return null;
    final data = _credentials.values.first;
    return {
      'npm': data['npm'] as String,
      'password': data['password'] as String,
    };
  }

  Future<Map<String, String>?> loadCredentialsByNpm(String npm) async {
    final data = _credentials.get(npm);
    if (data == null) return null;
    return {
      'npm': data['npm'] as String,
      'password': data['password'] as String,
    };
  }

  bool hasCredentials() => _credentials.isNotEmpty;

  Future<void> clearCredentials() async {
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
    final existing = _academic.get(npm) ?? {};
    existing['krs'] = data;
    await _academic.put(npm, existing);
  }

  Future<Map<String, dynamic>?> loadKrsData({required String npm}) async {
    final data = _academic.get(npm);
    return data?['krs'] as Map<String, dynamic>?;
  }

  bool hasKrsData({required String npm}) {
    final data = _academic.get(npm);
    return data != null && data['krs'] != null;
  }

  // KHS LIST
  Future<void> saveKhsList({
    required String npm,
    required List<dynamic> data,
  }) async {
    final existing = _academic.get(npm) ?? {};
    existing['khsList'] = data;
    await _academic.put(npm, existing);
  }

  Future<List<dynamic>?> loadKhsList({required String npm}) async {
    final data = _academic.get(npm);
    return data?['khsList'] as List<dynamic>?;
  }

  bool hasKhsList({required String npm}) {
    final data = _academic.get(npm);
    return data != null && data['khsList'] != null;
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
    final existing = _academic.get(npm) ?? {};
    final khs = Map<String, dynamic>.from(existing['khs'] ?? {});
    khs[_khsKey(tahunAjaran, semester)] = data;
    existing['khs'] = khs;
    await _academic.put(npm, existing);
  }

  Future<Map<String, dynamic>?> loadKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    final data = _academic.get(npm);
    final khs = data?['khs'] as Map<String, dynamic>?;
    return khs?[_khsKey(tahunAjaran, semester)] as Map<String, dynamic>?;
  }

  Future<bool> hasKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    final data = _academic.get(npm);
    final khs = data?['khs'] as Map<String, dynamic>?;
    return khs?.containsKey(_khsKey(tahunAjaran, semester)) ?? false;
  }

  // CHECK DATA EXISTS
  bool hasAcademicData({required String npm}) {
    final data = _academic.get(npm);
    return data != null && data.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearKrsData() async {
    // Clear KRS for all users
    for (final key in _academic.keys) {
      final data = _academic.get(key);
      if (data != null) {
        data.remove('krs');
        await _academic.put(key as String, data);
      }
    }
  }

  Future<void> clearKhsData() async {
    // Clear KHS for all users
    for (final key in _academic.keys) {
      final data = _academic.get(key);
      if (data != null) {
        data.remove('khs');
        data.remove('khsList');
        await _academic.put(key as String, data);
      }
    }
  }

  Future<void> clearAcademicData() async {
    await _academic.clear();
  }

  Future<void> clearAll() async {
    await _credentials.clear();
    await _academic.clear();
  }
}
