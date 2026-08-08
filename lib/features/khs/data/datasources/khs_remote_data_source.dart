import 'dart:developer' as developer;

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';

abstract class KhsRemoteDataSource {
  Future<List<KhsSemesterModel>> getSemesters({
    required String npm,
    required String password,
  });

  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  });

  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  });

  Future<KhsModel> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
  });
}

/// Real HTTP implementation via ApiClient.
class KhsRemoteDataSourceImpl implements KhsRemoteDataSource {
  final ApiClient apiClient;
  final AcademicCacheService academicCacheService;
  const KhsRemoteDataSourceImpl({
    required this.apiClient,
    required this.academicCacheService,
  });

  @override
  Future<List<KhsSemesterModel>> getSemesters({
    required String npm,
    required String password,
  }) async {
    // Always fetch fresh semesters from API (cache cleared elsewhere or not used for stale data)
    final response = await apiClient.post(
      '/api/v1/lms/khs/semesters',
      body: lmsCredentialBody(npm: npm, password: password),
    );
    final data = response;
    final semesters = data['semesters'] as List<dynamic>? ?? [];

    // Save to cache
    await academicCacheService.saveKhsList(npm: npm, data: semesters);

    return semesters
        .map((e) => KhsSemesterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) async {
    // Check if KHS data already exists in cache
    final cached = await academicCacheService.loadKhsDataSemester(
      npm: npm,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
    if (cached != null) {
      developer.log(
        'KHS already cached, skipping download: $semester',
        name: 'KhsDS',
      );
      return;
    }

    // Otherwise, download from API
    await apiClient.post(
      '/api/v1/lms/khs',
      body: lmsCredentialBody(
        npm: npm,
        password: password,
        tahunAjaran: tahunAjaran,
        semester: semester,
      ),
    );
  }

  @override
  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) async {
    // Check if KHS data already exists in cache
    final cached = await academicCacheService.loadKhsDataSemester(
      npm: npm,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
    if (cached != null) {
      developer.log(
        'KHS already cached, skipping extract: $semester',
        name: 'KhsDS',
      );
      return;
    }

    // Otherwise, extract from API
    await apiClient.post(
      '/api/v1/lms/khs/extract',
      body: lmsCredentialBody(
        npm: npm,
        password: password,
        tahunAjaran: tahunAjaran,
        semester: semester,
      ),
    );
  }

  @override
  Future<KhsModel> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    // Check cache first
    final cachedData = await academicCacheService.loadKhsDataSemester(
      npm: npm,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
    if (cachedData != null) {
      return KhsModel.fromJson(cachedData);
    }

    // Cache miss — hit endpoint
    final response = await apiClient.post(
      '/api/v1/lms/khs/data',
      body: {'npm': npm, 'tahun_ajaran': tahunAjaran, 'semester': semester},
    );

    // Save to cache
    await academicCacheService.saveKhsDataSemester(
      npm: npm,
      tahunAjaran: tahunAjaran,
      semester: semester,
      data: response,
    );

    return KhsModel.fromJson(response);
  }
}
