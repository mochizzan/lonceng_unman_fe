// home - Abstract data source (interface)
//
// Defines the contract for fetching home screen data from cache.
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/home/data/models/home_model.dart';
import 'dart:developer' as developer;

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

    // Read KHS data from cache — load all available semesters for IPK
    double gpaGanjil = 0.0;
    double gpaGenap = 0.0;
    String? khsSemester;
    try {
      // Try to load GANJIL KHS
      final ganjilKhs = await academicCacheService.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: krsData.periode.tahunAjaran,
        semester: 'GANJIL',
      );
      if (ganjilKhs != null) {
        final khsData = KhsModel.fromJson(ganjilKhs).khs;
        gpaGanjil = khsData.rekapitulasi.ipk;
        khsSemester ??= khsData.periode.semester;
      }
      // Try to load GENAP KHS
      final genapKhs = await academicCacheService.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: krsData.periode.tahunAjaran,
        semester: 'GENAP',
      );
      if (genapKhs != null) {
        final khsData = KhsModel.fromJson(genapKhs).khs;
        gpaGenap = khsData.rekapitulasi.ipk;
        khsSemester ??= khsData.periode.semester;
      }
    } catch (_) {
      // KHS may not be available yet if data-init hasn't completed.
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayName = weekdayToDayName(now.weekday);

    // Build today's schedule from KRS mata_kuliah
    developer.log(
      'Today: $todayDayName, MataKuliah count: ${krsData.mataKuliah.length}',
      name: 'HomeDataSource',
    );
    final todaySchedule =
        krsData.mataKuliah
            .where((mk) => mk.hari == todayDayName)
            .map((mk) => toScheduleItem(mk, today, now))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    developer.log(
      'Today schedule count: ${todaySchedule.length}',
      name: 'HomeDataSource',
    );

    // Find next upcoming/ongoing class
    final nextClass = _findNextClass(krsData.mataKuliah, today, now);

    return HomeModel(
      userName: krsData.mahasiswa.nama,
      avatarUrl: '',
      nextClass: nextClass,
      scheduleItems: todaySchedule,
      sksTaken: krsData.totalSks,
      todayClassCount: todaySchedule.length,
      semester: khsSemester ?? krsData.periode.semester,
      tahunAjaran: krsData.periode.tahunAjaran,
      studyProgram: krsData.mahasiswa.programStudi,
      gpaGanjil: gpaGanjil,
      gpaGenap: gpaGenap,
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
    final todayDayName = weekdayToDayName(now.weekday);

    // Build all schedule items for today
    final todayItems =
        mataKuliah
            .where((mk) => mk.hari == todayDayName)
            .map((mk) => toScheduleItem(mk, today, now))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Check for ongoing class first
    for (final item in todayItems) {
      if (item.status == ScheduleStatus.ongoing) {
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

    // Check for upcoming class today
    for (final item in todayItems) {
      if (item.status == ScheduleStatus.upcoming) {
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

    // No more classes today — find next day with classes (up to 14 days)
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    for (int offset = 1; offset <= 14; offset++) {
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

    return null;
  }
}
