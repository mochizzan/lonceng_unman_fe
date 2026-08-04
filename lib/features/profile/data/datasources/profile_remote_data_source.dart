// profile - Abstract data source (interface)
//
// Defines the contract for fetching profile screen data from a remote source.
// Follows the same pattern as jadwal's [JadwalRemoteDataSource].
import 'package:lonceng_unman_fe/features/profile/data/models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  /// Fetches profile screen data for the authenticated user.
  Future<ProfileModel> getProfile();
}

/// Stub implementation — returns mock data synchronously.
/// Replace with real HTTP client when backend is available.
class StubProfileRemoteDataSource implements ProfileRemoteDataSource {
  @override
  Future<ProfileModel> getProfile() async {
    return ProfileModel(
      userName: 'Aditya Pratama',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCnBIL5cJ77Nfm9Q8slewKAS_21_yT3yb1_sUdsHuAfpDTaur8eBGDEL9DXqSaJt9Xj3CpCwww0JaAiZ3StVnLWxDSopEerEkB0hKth_cn2VLnpolxeCKSad7lscm0kjKIVE4Bx8f13WERDCrGYRL-zyPjkPsOgHJ3dKi1o5ZZ6YKu8HwbtwkJcjIEjullt5LtSbQVf3Zf2jw4yx4qZwUxhTc-kKCG-ZHFj5hZlZRtFg56mASnX0kLOPA',
      npm: '20210140001',
      studyProgram: 'Teknik Informatika',
      semester: 'Semester 5',
      gpa: 3.85,
      sksTaken: 104,
      sksTotal: 120,
      todayClassCount: 3,
      bio:
          'Mahasiswa Teknik Informatika yang antusias dengan pengembangan web dan desain UI/UX. '
          'Berpengalaman dalam mengerjakan proyek perkuliahan berbasis JavaScript dan Figma.',
      reminderEnabled: true,
      darkModeEnabled: false,
      lastUpdated: DateTime(2024, 8, 4),
    );
  }
}
