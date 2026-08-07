// profile - Abstract data source (interface)
//
// Defines the contract for fetching profile screen data from cache.

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';
import 'package:lonceng_unman_fe/features/profile/data/models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  /// Fetches profile screen data for the authenticated user.
  Future<ProfileModel> getProfile();
}

/// Reads profile data from local cache only (no API calls).
///
/// All data is fetched during login via the expanded data-init pipeline.
/// This class reads KRS + KHS from [AcademicCacheService] and builds the
/// [ProfileModel] used by the Profile page.
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final AcademicCacheService academicCacheService;

  const ProfileRemoteDataSourceImpl({required this.academicCacheService});

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
      final khsJson = await academicCacheService.loadKhsData(npm: npm);
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
    final todayDayName = _weekdayToDayName(now.weekday);
    final todayClassCount = krsData.mataKuliah
        .where((mk) => mk.hari == todayDayName)
        .length;

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
      bio: null,
      reminderEnabled: true,
      darkModeEnabled: false,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Converts a Dart weekday int (1=Monday..7=Sunday) to Indonesian day name.
String _weekdayToDayName(int weekday) {
  const names = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
    7: 'Minggu',
  };
  return names[weekday] ?? '';
}
