// home - Abstract data source (interface)
//
// Defines the contract for fetching home screen data from a remote source.
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/home/data/models/home_model.dart';
import 'package:lonceng_unman_fe/features/khs/data/datasources/khs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

abstract class HomeRemoteDataSource {
  /// Fetches home screen data for the authenticated user.
  Future<HomeModel> getHomeData();
}

/// Real implementation that fetches data from KRS + KHS APIs.
///
/// The KRS endpoint provides schedule, semester, and student info.
/// The KHS endpoint provides GPA and cumulative SKS.
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final KrsRemoteDataSource krsDataSource;
  final KhsRemoteDataSource khsDataSource;
  final AcademicCacheService academicCacheService;

  const HomeRemoteDataSourceImpl({
    required this.krsDataSource,
    required this.khsDataSource,
    required this.academicCacheService,
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

    // Fetch KRS data (schedule, student info, semester)
    final krsResponse = await krsDataSource.getKrsData(npm: npm);
    final krsData = krsResponse.krs;

    // Fetch KHS data for GPA — use latest available semester
    double gpa = 0.0;
    try {
      // Get available KHS semesters to find the latest one
      // Note: getSemesters() needs password, which we load from cache
      final password = creds?['password'] ?? '';

      final semesters = await khsDataSource.getSemesters(
        npm: npm,
        password: password,
      );

      if (semesters.isNotEmpty) {
        // Pick the last semester (latest = most recent)
        final latest = semesters.last;

        final khsResponse = await khsDataSource.getKhsData(
          npm: npm,
          tahunAjaran: latest.tahunAjaran,
          semester: latest.semester,
        );
        gpa = khsResponse.khs.rekapitulasi.ipk;
      }
    } catch (_) {
      // KHS may not be available yet if data-init hasn't completed.
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayName = _weekdayToDayName(now.weekday);

    // Build today's schedule from KRS mata_kuliah
    final todaySchedule =
        krsData.mataKuliah
            .where((mk) => mk.hari == todayDayName)
            .map((mk) => _toScheduleItem(mk, today, now))
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
      semester: 'Semester ${krsData.periode.semester}',
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
    final todayDayName = _weekdayToDayName(now.weekday);
    final todayItems =
        mataKuliah
            .where((mk) => mk.hari == todayDayName)
            .map((mk) => _toScheduleItem(mk, today, now))
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
      final futureDayName = _weekdayToDayName(futureDate.weekday);
      if (!dayNames.contains(futureDayName)) continue;

      final futureItems =
          mataKuliah
              .where((mk) => mk.hari == futureDayName)
              .map((mk) => _toScheduleItem(mk, futureDate, now))
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

  /// Converts a KRS [MataKuliahKrsEntity] into a [ScheduleItemModel].
  ScheduleItemModel _toScheduleItem(
    MataKuliahKrsEntity mk,
    DateTime date,
    DateTime now,
  ) {
    final startTime = _parseTime(mk.jamMulai, date);
    final endTime = _parseTime(mk.jamSelesai, date);

    return ScheduleItemModel(
      courseName: mk.nama,
      room: '',
      startTime: startTime,
      endTime: endTime,
      lecturer: mk.dosen.isNotEmpty ? mk.dosen : null,
      sks: mk.sks > 0 ? '${mk.sks}' : null,
      status: _determineStatus(startTime, endTime, now),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────

/// Parses a "HH:MM" or "HH:MM:SS" time string into a [DateTime]
/// combined with the given [date].
DateTime _parseTime(String timeStr, DateTime date) {
  if (timeStr.isEmpty) return date;
  final parts = timeStr.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
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

/// Determines whether a class is ongoing, upcoming, or completed
/// based on the current time.
ScheduleStatus _determineStatus(DateTime start, DateTime end, DateTime now) {
  if (now.isAfter(start) && now.isBefore(end)) return ScheduleStatus.ongoing;
  if (now.isAfter(end)) return ScheduleStatus.completed;
  return ScheduleStatus.upcoming;
}
