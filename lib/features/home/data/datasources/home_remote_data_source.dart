// home - Abstract data source (interface)
//
// Defines the contract for fetching home screen data from cache.
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/home/data/models/home_model.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

abstract class HomeRemoteDataSource {
  /// Fetches home screen data for the authenticated user.
  Future<HomeModel> getHomeData();
}

/// Reads home screen data from local cache only (no API calls).
///
/// All data is fetched during login via the expanded data-init pipeline.
/// This class reads KRS + KHS from [AcademicCacheService] and builds the
/// [HomeModel] used by the Home page.
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final AcademicCacheService academicCacheService;

  const HomeRemoteDataSourceImpl({required this.academicCacheService});

  @override
  Future<HomeModel> getHomeData() async {
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
    String? khsSemester;
    try {
      final khsJson = await academicCacheService.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: krsData.periode.tahunAjaran,
        semester: krsData.periode.semester,
      );
      if (khsJson != null) {
        final khsData = KhsModel.fromJson(khsJson).khs;
        gpa = khsData.rekapitulasi.ipk;
        khsSemester = khsData.periode.semester;
      }
    } catch (_) {
      // KHS may not be available yet if data-init hasn't completed.
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayName = weekdayToDayName(now.weekday);

    // Build today's schedule from KRS mata_kuliah
    final todaySchedule =
        krsData.mataKuliah
            .where((mk) => mk.hari == todayDayName)
            .map((mk) => toScheduleItem(mk, today, now))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Find next upcoming/ongoing class
    final nextClass = _findNextClass(krsData.mataKuliah, today, now);

    return HomeModel(
      userName: krsData.mahasiswa.nama,
      avatarUrl: '',
      nextClass: nextClass,
      scheduleItems: todaySchedule,
      sksTaken: krsData.totalSks,
      sksTotal: 24, // Standard max SKS per semester
      todayClassCount: todaySchedule.length,
      semester: khsSemester ?? krsData.periode.semester,
      studyProgram: krsData.mahasiswa.programStudi,
      gpa: gpa,
    );
  }

  /// Finds the next upcoming/ongoing class across today and upcoming days.
  ///
  /// Returns `null` when there are no upcoming/ongoing classes in the
  /// schedule, allowing the hero card to display its empty state.
  NextClassModel? _findNextClass(
    List<MataKuliahKrsEntity> mataKuliah,
    DateTime today,
    DateTime now,
  ) {
    // Check today first
    final todayDayName = weekdayToDayName(now.weekday);
    final todayItems =
        mataKuliah
            .where((mk) => mk.hari == todayDayName)
            .map((mk) => toScheduleItem(mk, today, now))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final item in todayItems) {
      if (item.status == ScheduleStatus.upcoming ||
          item.status == ScheduleStatus.ongoing) {
        return NextClassModel(
          courseName: item.courseName,
          startTime: item.startTime,
          endTime: item.endTime,
          sks: item.sks ?? '',
          lecturer: item.lecturer,
          location: item.room,
        );
      }
    }

    // No more classes today — find the next day with classes
    const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
    for (int offset = 1; offset <= 7; offset++) {
      final futureDate = today.add(Duration(days: offset));
      final futureDayName = weekdayToDayName(futureDate.weekday);
      if (!dayNames.contains(futureDayName)) continue;

      final futureItems =
          mataKuliah
              .where((mk) => mk.hari == futureDayName)
              .map((mk) => toScheduleItem(mk, futureDate, now))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (futureItems.isNotEmpty) {
        final first = futureItems.first;
        return NextClassModel(
          courseName: first.courseName,
          startTime: first.startTime,
          endTime: first.endTime,
          sks: first.sks ?? '',
          lecturer: first.lecturer,
          location: first.room,
        );
      }
    }

    // No upcoming or ongoing classes found in the entire schedule.
    return null;
  }
}
