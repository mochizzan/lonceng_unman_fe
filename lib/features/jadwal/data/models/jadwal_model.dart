// jadwal - Data model
//
// DTO layer: converts between raw JSON data from the remote data source
// and domain [JadwalEntity] objects.
// Follows the same pattern as home's [HomeModel].

import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';

/// Raw model for a schedule item from the API.
class JadwalScheduleItemModel extends JadwalScheduleItem {
  const JadwalScheduleItemModel({
    required super.courseName,
    required super.startTime,
    required super.endTime,
    required super.room,
    required super.sks,
    required super.status,
    super.lecturer,
  });

  factory JadwalScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return JadwalScheduleItemModel(
      courseName: json['courseName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      lecturer: json['lecturer'] as String?,
      room: json['room'] as String,
      sks: json['sks'] as String,
      status: _parseStatus(json['status'] as String? ?? 'upcoming'),
    );
  }

  static JadwalScheduleStatus _parseStatus(String value) {
    switch (value) {
      case 'ongoing':
        return JadwalScheduleStatus.ongoing;
      case 'completed':
        return JadwalScheduleStatus.completed;
      case 'upcoming':
      default:
        return JadwalScheduleStatus.upcoming;
    }
  }
}

/// Top-level jadwal data model.
class JadwalModel extends JadwalEntity {
  const JadwalModel({
    required super.selectedDay,
    required super.days,
    required super.scheduleItems,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    final scheduleJson = json['scheduleItems'] as List<dynamic>;

    return JadwalModel(
      selectedDay: json['selectedDay'] as String,
      days: (json['days'] as List<dynamic>).cast<String>(),
      scheduleItems: scheduleJson
          .map(
            (e) => JadwalScheduleItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
