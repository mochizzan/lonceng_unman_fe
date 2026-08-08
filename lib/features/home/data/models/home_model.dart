// home - Data model
//
// DTO layer: converts between raw JSON data from the remote data source
// and domain [HomeEntity] objects.
// Follows the same pattern as auth's [AuthModel].

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
    required super.tahunAjaran,
    required super.studyProgram,
    required super.gpaGanjil,
    required super.gpaGenap,
  });
}
