import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Persists NPM + password to cache so the app can skip login on relaunch.
class CredentialCache {
  static const _fileName = 'credentials.json';

  Future<File> get _file async {
    final dir = await getApplicationCacheDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> save({required String npm, required String password}) async {
    final file = await _file;
    await file.writeAsString(jsonEncode({'npm': npm, 'password': password}));
  }

  Future<Map<String, String>?> load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return {
        'npm': map['npm'] as String,
        'password': map['password'] as String,
      };
    } catch (e) {
      developer.log('CredentialCache.load failed: $e', name: 'CredentialCache');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file;
      if (await file.exists()) await file.delete();
    } catch (e) {
      developer.log(
        'CredentialCache.clear failed: $e',
        name: 'CredentialCache',
      );
    }
  }
}
