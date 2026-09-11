// home - Abstract data source (interface)
//
// Defines the contract for fetching home screen data from cache.
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/home/data/models/home_model.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';

import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

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
  final StudentProfileCacheService studentProfileCacheService;

  const HomeRemoteDataSourceImpl({
    required this.academicCacheService,
    required this.studentProfileCacheService,
  });

  @override
  Future<HomeModel> getHomeData() async {
    final creds = await academicCacheService.loadCredentials();
    final npm = creds?['npm'];
    if (npm == null || npm.isEmpty) {
      throw const ValidationException(
        'NPM tidak ditemukan di kredensial. Silakan login ulang.',
      );
    }

    // 1. Tahun ajaran + IPK strict dari KHS (max khsList) — not from KRS.
    final khsList = await academicCacheService.loadKhsList(npm: npm);
    final latestYear = _latestTahunAjaran(khsList);
    double gpaGanjil = 0.0;
    double gpaGenap = 0.0;
    String? khsSemesterForLatest;
    if (latestYear.isNotEmpty) {
      try {
        final ganjilKhs = await academicCacheService.loadKhsDataSemester(
          npm: npm,
          tahunAjaran: latestYear,
          semester: 'GANJIL',
        );
        if (ganjilKhs != null) {
          final khsData = KhsModel.fromJson(ganjilKhs).khs;
          gpaGanjil = khsData.rekapitulasi.ipk;
          khsSemesterForLatest ??= khsData.periode.semester;
        }
        final genapKhs = await academicCacheService.loadKhsDataSemester(
          npm: npm,
          tahunAjaran: latestYear,
          semester: 'GENAP',
        );
        if (genapKhs != null) {
          final khsData = KhsModel.fromJson(genapKhs).khs;
          gpaGenap = khsData.rekapitulasi.ipk;
          khsSemesterForLatest ??= khsData.periode.semester;
        }
      } catch (_) {
        // KHS per-semester may not be cached yet.
      }
    }
    final tahunAjaran = latestYear; // "" if khsList empty → UI shows "-"

    // 2. isAlumni flag — reader only (written by KrsDS on 409/200/404).
    final isAlumni = await academicCacheService.loadIsAlumni(npm: npm);

    // 3. Jadwal from KRS — forced empty if alumni (even if stale cache remains race).
    List<ScheduleItemEntity> todaySchedule = const [];
    KrsDataEntity? krsData;
    int sksTaken = 0;
    NextClassEntity? nextClass;
    if (!isAlumni) {
      final krsJson = await academicCacheService.loadKrsData(npm: npm);
      if (krsJson != null) {
        try {
          krsData = KrsModel.fromJson(krsJson).krs;
        } catch (_) {}
      }
      if (krsData != null) {
        sksTaken = krsData.totalSks;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayDayName = weekdayToDayName(now.weekday);
        todaySchedule =
            (krsData.mataKuliah
                .where((mk) => mk.hari == todayDayName)
                .map((mk) => toScheduleItem(mk, today, now))
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime)));
        nextClass = _findNextClass(krsData.mataKuliah, today, now);
      }
    } else {
      todaySchedule = const [];
      nextClass = null;
      sksTaken = 0;
    }

    // 4. Profile override for userName/studyProgram/semester label
    // Priority: profile.semester > khsSemester(latestYear) > krs.semester
    String userName = krsData?.mahasiswa.nama ?? '';
    String studyProgram = krsData?.mahasiswa.programStudi ?? '';
    String semester = khsSemesterForLatest ?? krsData?.periode.semester ?? '';
    try {
      final profileJson = await studentProfileCacheService.loadProfile(
        npm: npm,
      );
      if (profileJson != null) {
        final profile = StudentProfileModel.fromJson(profileJson);
        userName = profile.namaMahasiswa.isNotEmpty
            ? profile.namaMahasiswa
            : userName;
        studyProgram = profile.programStudi.isNotEmpty
            ? profile.programStudi
            : studyProgram;
        semester = profile.semester.isNotEmpty ? profile.semester : semester;
        debugPrint('[HomeDS] Profile loaded from StudentProfileCacheService');
      }
    } catch (_) {
      // Student profile cache may not be available yet.
    }

    return HomeModel(
      userName: userName.isNotEmpty ? userName : 'Mahasiswa',
      avatarUrl: '',
      nextClass: nextClass,
      scheduleItems: todaySchedule,
      sksTaken: sksTaken,
      todayClassCount: todaySchedule.length,
      semester: semester.isNotEmpty ? semester : '-',
      tahunAjaran: tahunAjaran,
      studyProgram: studyProgram.isNotEmpty ? studyProgram : '-',
      gpaGanjil: gpaGanjil,
      gpaGenap: gpaGenap,
      isAlumni: isAlumni,
    );
  }

  /// Latest tahunAjaran from khsList — max by akhir year, handles
  /// both `tahunAjaran` and legacy `tahun_ajaran`.
  String _latestTahunAjaran(List<dynamic>? khsList) {
    if (khsList == null || khsList.isEmpty) return '';
    String? best;
    var bestAkhir = -1;
    for (final item in khsList) {
      if (item is! Map) continue;
      final ta = (item['tahunAjaran'] ?? item['tahun_ajaran']) as String?;
      if (ta == null || ta.isEmpty || !ta.contains('/')) continue;
      final parts = ta.split('/');
      final akhir = int.tryParse(parts.last.trim()) ?? -1;
      if (akhir > bestAkhir ||
          (akhir == bestAkhir && (best == null || ta.compareTo(best) > 0))) {
        bestAkhir = akhir;
        best = ta;
      }
    }
    return best ?? '';
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
