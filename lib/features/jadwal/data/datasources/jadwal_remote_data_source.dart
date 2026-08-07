// jadwal - Abstract data source (interface)
//
// Defines the contract for fetching weekly schedule data from a remote source.
// Follows the same pattern as home's [HomeRemoteDataSource].

import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/models/jadwal_model.dart';

abstract class JadwalRemoteDataSource {
  /// Fetches weekly schedule data for the authenticated user.
  Future<JadwalModel> getJadwal();
}

/// Stub implementation — returns mock data synchronously.
/// Replace with real HTTP client when backend is available.
class StubJadwalRemoteDataSource implements JadwalRemoteDataSource {
  @override
  Future<JadwalModel> getJadwal() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return JadwalModel(
      selectedDay: 'Senin',
      days: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
      scheduleItems: [
        ScheduleItemModel(
          courseName: 'Interaksi Manusia & Komputer',
          room: 'R. 301',
          startTime: today.add(const Duration(hours: 8)),
          endTime: today.add(const Duration(hours: 10, minutes: 30)),
          lecturer: 'Dr. Ir. Budi Santoso, M.Kom.',
          sks: '3 SKS',
          status: ScheduleStatus.ongoing,
        ),
        ScheduleItemModel(
          courseName: 'Algoritma & Pemrograman II',
          room: 'Lab Komputer 2',
          startTime: today.add(const Duration(hours: 11)),
          endTime: today.add(const Duration(hours: 13, minutes: 30)),
          lecturer: 'Dra. Sari Wulandari, M.Sc.',
          sks: '3 SKS',
          status: ScheduleStatus.upcoming,
        ),
        ScheduleItemModel(
          courseName: 'Etika Profesi & Hukum',
          room: 'R. 405',
          startTime: today.add(const Duration(hours: 14)),
          endTime: today.add(const Duration(hours: 15, minutes: 40)),
          lecturer: 'Prof. Dr. Ahmad Rizal, SH., MH.',
          sks: '2 SKS',
          status: ScheduleStatus.upcoming,
        ),
      ],
    );
  }
}
