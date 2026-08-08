import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';

class SaveAuthCredentials {
  final AcademicCacheService _cache;
  const SaveAuthCredentials(this._cache);

  Future<void> call({required String npm, required String password}) {
    return _cache.saveCredentials(npm: npm, password: password);
  }
}
