// profile - Abstract data source (interface)
//
// Defines the contract for fetching profile screen data from cache
// and refreshing from remote API.

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';
import 'package:lonceng_unman_fe/features/profile/data/models/profile_model.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';
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
  final StudentProfileCacheService studentProfileCacheService;

  const ProfileRemoteDataSourceImpl({
    required this.academicCacheService,
    required this.bioCacheService,
    required this.apiClient,
    required this.studentProfileCacheService,
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

    // 1. Load StudentProfile (primary source)
    String userName = '';
    String npmValue = npm;
    String studyProgram = '';
    String semester = '';
    try {
      final profileJson = await studentProfileCacheService.loadProfile(
        npm: npm,
      );
      if (profileJson != null) {
        final profile = StudentProfileModel.fromJson(profileJson);
        userName = profile.namaMahasiswa;
        npmValue = profile.nim.isNotEmpty ? profile.nim : npm;
        studyProgram = profile.programStudi;
        semester = profile.semester;
        debugPrint(
          '[ProfileDS] Profile loaded from StudentProfileCacheService',
        );
      }
    } catch (_) {}

    // 2. Fallback to KRS if StudentProfile is empty
    double gpa = 0.0;
    int cumulativeSks = 0;
    int todayClassCount = 0;
    final krsJson = await academicCacheService.loadKrsData(npm: npm);
    if (krsJson != null) {
      final krsData = KrsModel.fromJson(krsJson).krs;
      if (userName.isEmpty) userName = krsData.mahasiswa.nama;
      if (npmValue.isEmpty) npmValue = krsData.mahasiswa.npm;
      if (studyProgram.isEmpty) studyProgram = krsData.mahasiswa.programStudi;
      if (semester.isEmpty) semester = krsData.periode.semester;

      // Load KHS for GPA/SKS
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
      } catch (_) {}

      // Count today's classes
      final now = DateTime.now();
      final todayDayName = weekdayToDayName(now.weekday);
      todayClassCount = krsData.mataKuliah
          .where((mk) => mk.hari == todayDayName)
          .length;
    }

    // 3. Read bio from BioCacheService
    String? bio;
    try {
      bio = await bioCacheService.loadBio(npm: npm);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return ProfileModel(
      userName: userName.isNotEmpty ? userName : 'Mahasiswa',
      avatarUrl: '',
      npm: npmValue,
      studyProgram: studyProgram.isNotEmpty ? studyProgram : '-',
      semester: semester.isNotEmpty ? semester : '-',
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
