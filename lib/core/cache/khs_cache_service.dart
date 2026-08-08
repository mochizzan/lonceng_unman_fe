import 'dart:developer' as developer;
import 'package:hive_ce/hive.dart';

/// Manages KHS data with semester dimension using nested Hive boxes.
/// Box structure: box per NPM (khs_{npm}), key = tahunAjaran_semester
class KhsCacheService {
  KhsCacheService();

  String _key(String tahunAjaran, String semester) =>
      '${tahunAjaran}_$semester';

  String _boxName(String npm) => 'khs_$npm';

  Future<Box<dynamic>> _openBox(String npm) async {
    final name = _boxName(npm);
    try {
      if (!Hive.isBoxOpen(name)) {
        return await Hive.openBox<dynamic>(name);
      }
      return Hive.box<dynamic>(name);
    } catch (e) {
      developer.log('KHS box corrupted, recovering: $e', name: 'KhsCache');
      try {
        await Hive.deleteBoxFromDisk(name);
        return await Hive.openBox<dynamic>(name);
      } catch (e2) {
        developer.log('KHS recovery failed: $e2', name: 'KhsCache');
        rethrow;
      }
    }
  }

  Future<void> save({
    required String npm,
    required String tahunAjaran,
    required String semester,
    required Map<String, dynamic> data,
  }) async {
    try {
      final box = await _openBox(npm);
      await box.put(_key(tahunAjaran, semester), data);
      developer.log('KHS saved: $npm/$tahunAjaran/$semester', name: 'KhsCache');
    } catch (e) {
      developer.log('KHS save failed: $e', name: 'KhsCache', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> load({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    try {
      final box = await _openBox(npm);
      return box.get(_key(tahunAjaran, semester)) as Map<String, dynamic>?;
    } catch (e) {
      developer.log('KHS load failed: $e', name: 'KhsCache', error: e);
      return null;
    }
  }

  Future<bool> has({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    try {
      final box = await _openBox(npm);
      return box.containsKey(_key(tahunAjaran, semester));
    } catch (e) {
      return false;
    }
  }

  Future<void> clear({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    try {
      final box = await _openBox(npm);
      await box.delete(_key(tahunAjaran, semester));
    } catch (e) {
      developer.log('KHS clear failed: $e', name: 'KhsCache', error: e);
    }
  }

  Future<void> clearAll({required String npm}) async {
    try {
      final box = await _openBox(npm);
      await box.clear();
    } catch (e) {
      developer.log('KHS clearAll failed: $e', name: 'KhsCache', error: e);
    }
  }
}
