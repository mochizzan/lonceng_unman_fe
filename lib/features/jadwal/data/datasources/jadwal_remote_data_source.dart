// jadwal - Abstract data source (interface)
//
// Defines the contract for fetching weekly schedule data from a remote source.

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';
import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/models/jadwal_model.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';

abstract class JadwalRemoteDataSource {
  /// Fetches weekly schedule data for the authenticated user.
  Future<JadwalModel> getJadwal();
}

/// Real implementation that fetches schedule from the KRS API.
class JadwalRemoteDataSourceImpl implements JadwalRemoteDataSource {
  final KrsRemoteDataSource krsDataSource;
  final AcademicCacheService academicCacheService;

  const JadwalRemoteDataSourceImpl({
    required this.krsDataSource,
    required this.academicCacheService,
  });

  @override
  Future<JadwalModel> getJadwal() async {
    final creds = await academicCacheService.loadCredentials();
    final npm = creds?['npm'];
    if (npm == null || npm.isEmpty) {
      throw const ValidationException(
        'NPM tidak ditemukan di kredensial. Silakan login ulang.',
      );
    }

    final krsResponse = await krsDataSource.getKrsData(npm: npm);
    final mataKuliah = krsResponse.krs.mataKuliah;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayName = weekdayToDayName(now.weekday);

    // All 7 days of the week
    const allDays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    // Determine which days have classes
    final daysWithClasses = <String>{};
    for (final mk in mataKuliah) {
      if (allDays.contains(mk.hari)) {
        daysWithClasses.add(mk.hari);
      }
    }

    // Build day list: ALWAYS show all 7 days + "Semua"
    final orderedDays = <String>['Semua', ...allDays];

    // Default selection: today if it has classes, otherwise "Semua"
    final selectedDay = daysWithClasses.contains(todayDayName)
        ? todayDayName
        : 'Semua';

    // Build schedule items
    List<ScheduleItemModel> scheduleItems;
    if (selectedDay == 'Semua') {
      // Show all classes for the week, sorted by day then time
      scheduleItems =
          mataKuliah.map((mk) {
            final dayIndex = allDays.indexOf(mk.hari);
            final date = today.add(
              Duration(days: (dayIndex + 1 - today.weekday) % 7),
            );
            return toScheduleItem(mk, date, now, suffix: 'SKS');
          }).toList()..sort((a, b) {
            final dayA = weekdayToDayName(a.startTime.weekday);
            final dayB = weekdayToDayName(b.startTime.weekday);
            final dayCmp = kDayOrder
                .indexOf(dayA)
                .compareTo(kDayOrder.indexOf(dayB));
            if (dayCmp != 0) return dayCmp;
            return a.startTime.compareTo(b.startTime);
          });
    } else {
      // Show classes for the selected day only
      final selectedDate = _dateForDay(selectedDay, today);
      scheduleItems =
          mataKuliah
              .where((mk) => mk.hari == selectedDay)
              .map((mk) => toScheduleItem(mk, selectedDate, now, suffix: 'SKS'))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return JadwalModel(
      selectedDay: selectedDay,
      days: orderedDays,
      scheduleItems: scheduleItems,
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────

/// Returns the next occurrence of the given Indonesian [dayName] from [today].
/// For weekly schedules: if today is Wednesday and target is Monday,
/// returns next Monday (not last Monday).
DateTime _dateForDay(String dayName, DateTime today) {
  const dayToWeekday = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };
  final targetWeekday = dayToWeekday[dayName] ?? 1;
  int diff = targetWeekday - today.weekday;
  if (diff < 0) diff += 7;
  if (diff == 0) return today;
  return today.add(Duration(days: diff));
}
