import 'package:flutter/foundation.dart' show debugPrint;

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';

abstract class KrsRemoteDataSource {
  Future<void> downloadKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  });
  Future<void> extractKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  });
  Future<KrsModel> getKrsData({required String npm, bool forceRefresh = false});
}

/// Real HTTP implementation via ApiClient with AcademicCacheService caching.
class KrsRemoteDataSourceImpl implements KrsRemoteDataSource {
  final ApiClient apiClient;
  final AcademicCacheService academicCacheService;
  const KrsRemoteDataSourceImpl({
    required this.apiClient,
    required this.academicCacheService,
  });

  @override
  Future<void> downloadKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    // Check if KRS data already exists in cache (skip if forceRefresh)
    if (!forceRefresh) {
      final cached = await academicCacheService.loadKrsData(npm: npm);
      if (cached != null) {
        debugPrint('[KrsDS] KRS already cached, skipping download');
        return;
      }
    }

    // Otherwise, download from API
    await apiClient.post(
      '/api/v1/lms/krs',
      body: lmsCredentialBody(npm: npm, password: password),
    );
  }

  @override
  Future<void> extractKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    // Check if KRS data already exists in cache (skip if forceRefresh)
    if (!forceRefresh) {
      final cached = await academicCacheService.loadKrsData(npm: npm);
      if (cached != null) {
        debugPrint('[KrsDS] KRS already cached, skipping extract');
        return;
      }
    }

    // Otherwise, extract from API
    await apiClient.post(
      '/api/v1/lms/krs/extract',
      body: lmsCredentialBody(npm: npm, password: password),
    );
  }

  @override
  Future<KrsModel> getKrsData({
    required String npm,
    bool forceRefresh = false,
  }) async {
    // Check cache first (skip if forceRefresh)
    if (!forceRefresh) {
      final cachedData = await academicCacheService.loadKrsData(npm: npm);
      if (cachedData != null) {
        return KrsModel.fromJson(cachedData);
      }
    }

    // Cache miss — fetch from endpoint.
    try {
      final response = await apiClient.post(
        '/api/v1/lms/krs/data',
        body: {'npm': npm},
      );

      // Success → persist KRS + clear alumni flag (transient).
      await academicCacheService.saveKrsData(npm: npm, data: response);
      await academicCacheService.saveIsAlumni(npm: npm, isAlumni: false);

      return KrsModel.fromJson(response);
    } on AlumniException {
      // BE 409 ALUMNI gate — MUST be before AppException.
      // Invalidate KRS cache now (not retain stale), set alumni flag.
      await academicCacheService.clearKrsDataFor(npm: npm);
      await academicCacheService.saveIsAlumni(npm: npm, isAlumni: true);
      rethrow;
    } on AppException {
      // 404/500/403/network-wrapped — not alumni → flag false per spec transient.
      // Do NOT clear KRS cache — retain existing for fallback.
      try {
        await academicCacheService.saveIsAlumni(npm: npm, isAlumni: false);
      } catch (_) {}
      rethrow;
    }
  }
}
