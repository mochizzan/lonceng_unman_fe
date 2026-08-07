// jadwal - Abstract data source (interface)
//
// Defines the contract for fetching weekly schedule data from a remote source.

import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/models/jadwal_model.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

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
      throw Exception('NPM not found in credentials. Please log in again.');
    }

    final krsResponse = await krsDataSource.getKrsData(npm: npm);
    final mataKuliah = krsResponse.krs.mataKuliah;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayName = _weekdayToDayName(now.weekday);

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

    // Build day list: "Semua" first, then only days that have classes
    final orderedDays = <String>[
      'Semua',
      ...allDays.where((d) => daysWithClasses.contains(d)),
    ];

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
            return _toScheduleItem(mk, date, now);
          }).toList()..sort((a, b) {
            final dayCmp = allDays
                .indexOf(a.courseName)
                .compareTo(allDays.indexOf(b.courseName));
            if (dayCmp != 0) return dayCmp;
            return a.startTime.compareTo(b.startTime);
          });
    } else {
      // Show classes for the selected day only
      final selectedDate = _dateForDay(selectedDay, today);
      scheduleItems =
          mataKuliah
              .where((mk) => mk.hari == selectedDay)
              .map((mk) => _toScheduleItem(mk, selectedDate, now))
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

/// Converts a Dart weekday int to Indonesian day name.
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

/// Returns the date for the given Indonesian [dayName] in the current week.
/// If [dayName] is today, returns [today].
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
  final daysUntil = (targetWeekday - today.weekday) % 7;
  return today.add(Duration(days: daysUntil));
}

/// Parses a "HH:MM" time string into a [DateTime] on the given [date].
DateTime _parseTime(String timeStr, DateTime date) {
  if (timeStr.isEmpty) return date;
  final parts = timeStr.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Converts a KRS [MataKuliahKrsEntity] to a [ScheduleItemModel].
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
    sks: mk.sks > 0 ? '${mk.sks} SKS' : null,
    status: _determineStatus(startTime, endTime, now),
  );
}

/// Determines schedule status based on current time.
ScheduleStatus _determineStatus(DateTime start, DateTime end, DateTime now) {
  if (now.isAfter(start) && now.isBefore(end)) return ScheduleStatus.ongoing;
  if (now.isAfter(end)) return ScheduleStatus.completed;
  return ScheduleStatus.upcoming;
}
