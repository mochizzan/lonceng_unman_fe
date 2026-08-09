// profile - Abstract data source (interface)
//
// Defines the contract for fetching profile screen data from cache
// and refreshing from remote API.

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';
import 'package:lonceng_unman_fe/features/profile/data/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ProfileRemoteDataSource {
  /// Fetches profile screen data for the authenticated user.
  Future<ProfileModel> getProfile();

  /// Fetches KRS + KHS from remote API and updates local cache.
  Future<void> refreshFromRemote();
}

/// Reads profile data from local cache (built from KRS + KHS).
///
/// [refreshFromRemote] fetches fresh KRS + KHS from the API and saves
/// them to cache so the next [getProfile] call returns updated data.
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final AcademicCacheService academicCacheService;
  final BioCacheService bioCacheService;
  final ApiClient apiClient;

  const ProfileRemoteDataSourceImpl({
    required this.academicCacheService,
    required this.bioCacheService,
    required this.apiClient,
  });

  @override
  Future<ProfileModel> getProfile() async {
    final creds = await academicCacheService.loadCredentials();
    final npm = creds?['npm'];
    if (npm == null || npm.isEmpty) {
      throw const ValidationException(
        'NPM tidak ditemukan di kredensial. Silakan login ulang.',
      );
    }

    // Read KRS data from cache
    final krsJson = await academicCacheService.loadKrsData(npm: npm);
    if (krsJson == null) {
      throw const ValidationException(
        'Data KRS belum tersedia. Silakan login ulang.',
      );
    }
    final krsData = KrsModel.fromJson(krsJson).krs;

    // Read KHS data from cache (optional — may not be available yet)
    double gpa = 0.0;
    int cumulativeSks = 0;
    try {
      final khsJson = await academicCacheService.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: krsData.periode.tahunAjaran,
        semester: krsData.periode.semester,
      );
      if (khsJson != null) {
        final khsData = KhsModel.fromJson(khsJson).khs;
        gpa = khsData.rekapitulasi.ipk;
        cumulativeSks = khsData.rekapitulasi.totalSks;
      }
    } catch (_) {
      // KHS may not be available yet if data-init hasn't completed.
    }

    // Count today's classes
    final now = DateTime.now();
    final todayDayName = weekdayToDayName(now.weekday);
    final todayClassCount = krsData.mataKuliah
        .where((mk) => mk.hari == todayDayName)
        .length;

    // Read bio from BioCacheService
    String? bio;
    try {
      bio = await bioCacheService.loadBio(npm: npm);
    } catch (_) {
      // Bio may not exist yet or box may be corrupted
    }

    final prefs = await SharedPreferences.getInstance();
    return ProfileModel(
      userName: krsData.mahasiswa.nama,
      avatarUrl: '',
      npm: krsData.mahasiswa.npm,
      studyProgram: krsData.mahasiswa.programStudi,
      semester: krsData.periode.semester,
      gpa: gpa,
      sksTaken: cumulativeSks,
      sksTotal: 120, // Standard graduation requirement
      todayClassCount: todayClassCount,
      bio: bio,
      reminderEnabled: prefs.getBool('reminder_enabled') ?? true,
      darkModeEnabled: prefs.getBool('dark_mode_enabled') ?? false,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<void> refreshFromRemote() async {
    final creds = await academicCacheService.loadCredentials();
    final npm = creds?['npm'];
    if (npm == null || npm.isEmpty) return;

    // Fetch fresh KRS data from API and save to cache.
    final krsResponse = await apiClient.post(
      '/api/v1/lms/krs/data',
      body: {'npm': npm},
    );
    await academicCacheService.saveKrsData(npm: npm, data: krsResponse);

    // Parse KRS to get current semester info for KHS fetch.
    final krsData = KrsModel.fromJson(krsResponse).krs;

    // Fetch fresh KHS data from API and save to cache.
    final khsResponse = await apiClient.post(
      '/api/v1/lms/khs/data',
      body: {
        'npm': npm,
        'tahun_ajaran': krsData.periode.tahunAjaran,
        'semester': krsData.periode.semester,
      },
    );
    await academicCacheService.saveKhsDataSemester(
      npm: npm,
      tahunAjaran: krsData.periode.tahunAjaran,
      semester: krsData.periode.semester,
      data: khsResponse,
    );
  }
}
