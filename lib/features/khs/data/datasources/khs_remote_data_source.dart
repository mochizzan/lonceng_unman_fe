import 'package:flutter/foundation.dart' show debugPrint;

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
    bool forceRefresh = false,
  });

  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  });

  Future<KhsModel> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
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
    final rawSemesters = data['semesters'] as List<dynamic>? ?? [];
    final normalized = rawSemesters.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      final taRaw = m['tahunAjaran'] ?? m['tahun_ajaran'];
      String tahunAjaran;
      if (taRaw is Map) {
        final tam = Map<String, dynamic>.from(taRaw);
        final awal = tam['awal'] as String? ?? '';
        final akhir = tam['akhir'] as String? ?? '';
        if (awal.isNotEmpty && akhir.isNotEmpty) {
          tahunAjaran = '$awal/$akhir';
        } else {
          tahunAjaran =
              tam['tahunAjaran'] as String? ??
              tam['tahun_ajaran'] as String? ??
              '';
        }
      } else if (taRaw is String) {
        tahunAjaran = taRaw;
      } else {
        tahunAjaran = '';
      }
      final sksRaw = m['sks'];
      final sksNum = sksRaw is num
          ? sksRaw.toInt()
          : int.tryParse('$sksRaw') ?? 0;
      return {
        'tahunAjaran': tahunAjaran,
        'semester': m['semester'] as String? ?? '',
        'sks': sksNum,
      };
    }).toList();

    // Save normalized to cache (contract: tahunAjaran camelCase)
    await academicCacheService.saveKhsList(npm: npm, data: normalized);

    return normalized
        .map((e) => KhsSemesterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  }) async {
    // Check if KHS data already exists in cache (skip if forceRefresh)
    if (!forceRefresh) {
      final cached = await academicCacheService.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: tahunAjaran,
        semester: semester,
      );
      if (cached != null) {
        debugPrint('[KhsDS] KHS already cached, skipping download: $semester');
        return;
      }
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
    bool forceRefresh = false,
  }) async {
    // Check if KHS data already exists in cache (skip if forceRefresh)
    if (!forceRefresh) {
      final cached = await academicCacheService.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: tahunAjaran,
        semester: semester,
      );
      if (cached != null) {
        debugPrint('[KhsDS] KHS already cached, skipping extract: $semester');
        return;
      }
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
    bool forceRefresh = false,
  }) async {
    // Check cache first (skip if forceRefresh)
    if (!forceRefresh) {
      final cachedData = await academicCacheService.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: tahunAjaran,
        semester: semester,
      );
      if (cachedData != null) {
        return KhsModel.fromJson(cachedData);
      }
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
