// profile - Abstract data source (interface)
//
// Defines the contract for fetching profile screen data from a remote source.

import 'package:lonceng_unman_fe/core/cache/credential_cache.dart';
import 'package:lonceng_unman_fe/features/khs/data/datasources/khs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  /// Fetches profile screen data for the authenticated user.
  Future<ProfileModel> getProfile();
}

/// Real implementation that fetches profile data from KRS + KHS APIs.
///
/// KRS provides student identity and current schedule.
/// KHS provides GPA and cumulative SKS.
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final KrsRemoteDataSource krsDataSource;
  final KhsRemoteDataSource khsDataSource;
  final CredentialCache credentialCache;

  const ProfileRemoteDataSourceImpl({
    required this.krsDataSource,
    required this.khsDataSource,
    required this.credentialCache,
  });

  @override
  Future<ProfileModel> getProfile() async {
    final creds = await credentialCache.load();
    final npm = creds?['npm'];
    if (npm == null || npm.isEmpty) {
      throw Exception('NPM not found in credentials. Please log in again.');
    }

    // Fetch KRS data (student info, semester, schedule)
    final krsResponse = await krsDataSource.getKrsData(npm: npm);
    final krsData = krsResponse.krs;

    // Fetch KHS data for GPA and cumulative SKS
    double gpa = 0.0;
    int cumulativeSks = 0;
    try {
      final khsResponse = await khsDataSource.getKhsData(
        npm: npm,
        tahunAjaran: krsData.periode.tahunAjaran,
        semester: krsData.periode.semester,
      );
      gpa = khsResponse.khs.rekapitulasi.ipk;
      cumulativeSks = khsResponse.khs.rekapitulasi.totalSks;
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
      semester: 'Semester ${krsData.periode.semester}',
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
