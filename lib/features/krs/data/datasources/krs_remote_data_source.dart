import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';

abstract class KrsRemoteDataSource {
  Future<void> downloadKrs({required String npm, required String password});
  Future<void> extractKrs({required String npm, required String password});
  Future<KrsModel> getKrsData({required String npm});
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
  }) async {
    await apiClient.post(
      '/api/v1/lms/krs',
      body: lmsCredentialBody(npm: npm, password: password),
    );
  }

  @override
  Future<void> extractKrs({
    required String npm,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/api/v1/lms/krs/extract',
      body: lmsCredentialBody(npm: npm, password: password),
    );
    // Save extracted KRS data to cache after successful extraction.
    await academicCacheService.saveKrsData(npm: npm, data: response);
  }

  @override
  Future<KrsModel> getKrsData({required String npm}) async {
    // Check cache first.
    final cachedData = await academicCacheService.loadKrsData(npm: npm);
    if (cachedData != null) {
      return KrsModel.fromJson(cachedData);
    }

    // Cache miss — fetch from endpoint.
    final response = await apiClient.post(
      '/api/v1/lms/krs/data',
      body: {'npm': npm},
    );

    // Save response to cache for future requests.
    await academicCacheService.saveKrsData(npm: npm, data: response);

    return KrsModel.fromJson(response);
  }
}
