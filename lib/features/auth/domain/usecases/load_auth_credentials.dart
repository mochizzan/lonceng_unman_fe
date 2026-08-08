import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';

class LoadAuthCredentials {
  final AcademicCacheService _cache;
  const LoadAuthCredentials(this._cache);

  Future<Map<String, String>?> call() => _cache.loadCredentials();
}
