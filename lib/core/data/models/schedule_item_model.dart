// Shared schedule item model for the home and jadwal features.
//
// DTO layer for [ScheduleItemEntity] — handles common JSON parsing.
// Feature-specific models (with their own [fromJson]) extend this.

import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';

/// Shared schedule item model with a generic [fromJson] that handles
/// both home and jadwal JSON shapes (group, sks, etc.).
class ScheduleItemModel extends ScheduleItemEntity {
  const ScheduleItemModel({
    required super.courseName,
    required super.room,
    required super.startTime,
    required super.endTime,
    super.lecturer,
    super.group,
    super.sks,
    super.status,
  });

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleItemModel(
      courseName: json['courseName'] as String? ?? '',
      room: json['room'] as String? ?? '',
      startTime:
          DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
      lecturer: json['lecturer'] as String?,
      group: json['group'] as String?,
      sks: json['sks'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'upcoming'),
    );
  }

  static ScheduleStatus _parseStatus(String value) {
    switch (value) {
      case 'ongoing':
        return ScheduleStatus.ongoing;
      case 'completed':
        return ScheduleStatus.completed;
      case 'upcoming':
      default:
        return ScheduleStatus.upcoming;
    }
  }
}
