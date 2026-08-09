// student_profile_remote_data_source.dart
//
// Remote data source untuk data profil mahasiswa.
// Mengikuti pattern dari KrsRemoteDataSource.
// Menggunakan ApiClient untuk HTTP dan StudentProfileCacheService untuk caching.

import 'dart:developer' as developer;

import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

/// Abstract interface untuk remote data source profil mahasiswa.
abstract class StudentProfileRemoteDataSource {
  /// Melakukan scrape data profil dari LMS.
  ///
  /// Endpoint: POST /api/v1/lms/student-profile
  /// Body: { npm, password }
  Future<void> scrapeProfile({required String npm, required String password});

  /// Mendapatkan data profil mahasiswa.
  ///
  /// Endpoint: POST /api/v1/lms/student-profile/data
  /// Body: { npm, password }
  ///
  /// Mengembalikan [StudentProfileModel] dari cache jika ada,
  /// atau dari API jika tidak ada di cache.
  Future<StudentProfileModel> getProfile({
    required String npm,
    required String password,
  });
}

/// Implementasi real HTTP via ApiClient dengan caching via StudentProfileCacheService.
///
/// Pattern: sama seperti KrsRemoteDataSourceImpl.
/// - scrapeProfile: POST ke /api/v1/lms/student-profile
/// - getProfile: POST ke /api/v1/lms/student-profile/data, cache hasilnya
class StudentProfileRemoteDataSourceImpl
    implements StudentProfileRemoteDataSource {
  final ApiClient apiClient;
  final StudentProfileCacheService cacheService;

  const StudentProfileRemoteDataSourceImpl({
    required this.apiClient,
    required this.cacheService,
  });

  @override
  Future<void> scrapeProfile({
    required String npm,
    required String password,
  }) async {
    // Cek apakah data sudah ada di cache
    final hasCached = cacheService.hasProfile(npm: npm);
    if (hasCached) {
      developer.log(
        'Profil sudah ter-cache, skip scrape',
        name: 'StudentProfileDS',
      );
      return;
    }

    // Scrape dari API
    await apiClient.post(
      '/api/v1/lms/student-profile',
      body: lmsCredentialBody(npm: npm, password: password),
    );
  }

  @override
  Future<StudentProfileModel> getProfile({
    required String npm,
    required String password,
  }) async {
    // Cek cache dulu
    final cachedData = await cacheService.loadProfile(npm: npm);
    if (cachedData != null) {
      developer.log('Profil ditemukan di cache', name: 'StudentProfileDS');
      return StudentProfileModel.fromJson(cachedData);
    }

    // Cache miss — fetch dari endpoint
    final response = await apiClient.post(
      '/api/v1/lms/student-profile/data',
      body: lmsCredentialBody(npm: npm, password: password),
    );

    // Simpan ke cache untuk request selanjutnya
    await cacheService.saveProfile(npm: npm, profileData: response);

    return StudentProfileModel.fromJson(response);
  }
}
