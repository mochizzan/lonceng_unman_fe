import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

/// Converts Dart weekday int (1=Monday..7=Sunday) to Indonesian day name.
String weekdayToDayName(int weekday) {
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

/// Returns ordered list of day names for sorting (Mon–Sun).
const List<String> kDayOrder = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// Parses "HH:MM" or "HH:MM:SS" time string into DateTime combined with date.
/// Returns [date] unchanged if [timeStr] is empty.
DateTime parseTime(String timeStr, DateTime date) {
  if (timeStr.isEmpty) return date;
  final parts = timeStr.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Determines schedule status based on current time.
ScheduleStatus determineStatus(DateTime start, DateTime end, DateTime now) {
  if (now.isAfter(start) && now.isBefore(end)) return ScheduleStatus.ongoing;
  if (now.isAfter(end)) return ScheduleStatus.completed;
  return ScheduleStatus.upcoming;
}

/// Converts KRS MataKuliahKrsEntity to ScheduleItemModel.
/// [suffix] appended to SKS value (e.g., "SKS"). Pass null for no suffix.
ScheduleItemModel toScheduleItem(
  MataKuliahKrsEntity mk,
  DateTime date,
  DateTime now, {
  String? suffix,
}) {
  final startTime = parseTime(mk.jamMulai, date);
  final endTime = parseTime(mk.jamSelesai, date);
  final sksStr = mk.sks > 0
      ? (suffix != null ? '${mk.sks} $suffix' : '${mk.sks}')
      : null;
  return ScheduleItemModel(
    courseName: mk.nama,
    room: '',
    startTime: startTime,
    endTime: endTime,
    lecturer: mk.dosen.isNotEmpty ? mk.dosen : null,
    sks: sksStr,
    status: determineStatus(startTime, endTime, now),
    dayOfWeek: mk.hari,
  );
}
