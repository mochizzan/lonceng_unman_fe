// home - Data model
//
// DTO layer: converts between raw JSON data from the remote data source
// and domain [HomeEntity] objects.
// Follows the same pattern as auth's [AuthModel].

import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';

/// Raw model for the next class from the API.
class NextClassModel extends NextClassEntity {
  const NextClassModel({
    required super.courseName,
    required super.startTime,
    required super.endTime,
    required super.sks,
    super.lecturer,
    super.location,
  });

  factory NextClassModel.fromJson(Map<String, dynamic> json) {
    return NextClassModel(
      courseName: json['courseName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      sks: json['sks'] as String,
      lecturer: json['lecturer'] as String?,
      location: json['location'] as String?,
    );
  }
}

/// Top-level home data model.
class HomeModel extends HomeEntity {
  const HomeModel({
    required super.userName,
    required super.avatarUrl,
    super.nextClass,
    required super.scheduleItems,
    required super.sksTaken,
    required super.todayClassCount,
    required super.semester,
    required super.studyProgram,
    required super.gpaGanjil,
    required super.gpaGenap,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    final nextClassJson = json['nextClass'] as Map<String, dynamic>?;
    final scheduleJson = json['scheduleItems'] as List<dynamic>;

    return HomeModel(
      userName: json['userName'] as String,
      avatarUrl: json['avatarUrl'] as String,
      nextClass: nextClassJson != null
          ? NextClassModel.fromJson(nextClassJson)
          : null,
      scheduleItems: scheduleJson
          .map((e) => ScheduleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sksTaken: json['sksTaken'] as int,
      todayClassCount: json['todayClassCount'] as int,
      semester: json['semester'] as String,
      studyProgram: json['studyProgram'] as String,
      gpaGanjil: (json['gpaGanjil'] as num?)?.toDouble() ?? 0.0,
      gpaGenap: (json['gpaGenap'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
