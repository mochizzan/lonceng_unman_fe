// home - Abstract data source (interface)
//
// Defines the contract for fetching home screen data from a remote source.
import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/home/data/models/home_model.dart';

abstract class HomeRemoteDataSource {
  /// Fetches home screen data for the authenticated user.
  Future<HomeModel> getHomeData();
}

/// Stub implementation — returns mock data synchronously.
/// Replace with real HTTP client when backend is available.
class StubHomeRemoteDataSource implements HomeRemoteDataSource {
  @override
  Future<HomeModel> getHomeData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final baseDate = today.add(const Duration(days: 3));

    return HomeModel(
      userName: 'Aditya',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCnBIL5cJ77Nfm9Q8slewKAS_21_yT3yb1_sUdsHuAfpDTaur8eBGDEL9DXqSaJt9Xj3CpCwww0JaAiZ3StVnLWxDSopEerEkB0hKth_cn2VLnpolxeCKSad7lscm0kjKIVE4Bx8f13WERDCrGYRL-zyPjkPsOgHJ3dKi1o5ZZ6YKu8HwbtwkJcjIEjullt5LtSbQVf3Zf2jw4yx4qZwUxhTc-kKCG-ZHFj5hZlZRtFg56mASnX0kLOPA',
      nextClass: NextClassModel(
        courseName: 'Sistem Basis Data',
        startTime: baseDate.add(const Duration(hours: 9, minutes: 15)),
        endTime: baseDate.add(const Duration(hours: 10, minutes: 45)),
        sks: '3 SKS',
        lecturer: 'Dr. Aris Sudarman',
        location: 'Lab Komputer 3',
      ),
      scheduleItems: [
        ScheduleItemModel(
          courseName: 'Algoritma Lanjut',
          room: 'R. 402',
          startTime: baseDate.add(const Duration(hours: 8)),
          endTime: baseDate.add(const Duration(hours: 10, minutes: 30)),
          lecturer: 'Dr. Aris Sudarman',
          group: 'Kelas A',
          status: ScheduleStatus.ongoing,
        ),
        ScheduleItemModel(
          courseName: 'Sistem Basis Data',
          room: 'Lab Komp 3',
          startTime: baseDate.add(const Duration(hours: 11)),
          endTime: baseDate.add(const Duration(hours: 12, minutes: 30)),
          status: ScheduleStatus.upcoming,
        ),
        ScheduleItemModel(
          courseName: 'Kewirausahaan',
          room: 'R. Teater 1',
          startTime: baseDate.add(const Duration(hours: 14)),
          endTime: baseDate.add(const Duration(hours: 15, minutes: 30)),
          status: ScheduleStatus.upcoming,
        ),
      ],
      sksTaken: 22,
      sksTotal: 24,
      todayClassCount: 3,
      semester: 'Semester 5',
      studyProgram: 'Teknik Informatika',
      gpa: 3.85,
    );
  }
}
