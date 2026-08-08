// home - Entity
//
// Domain-layer entity representing the aggregated home screen data.
// Follows Clean Architecture: domain layer has no framework dependencies.

import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';

/// The next upcoming class, used for the countdown hero card.
class NextClassEntity {
  const NextClassEntity({
    required this.courseName,
    required this.startTime,
    required this.endTime,
    required this.sks,
    this.lecturer,
    this.location,
  });

  final String courseName;
  final DateTime startTime;
  final DateTime endTime;
  final String sks;
  final String? lecturer;
  final String? location;

  /// Time remaining from now until [startTime].
  Duration timeRemaining(DateTime now) => startTime.difference(now);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextClassEntity &&
          runtimeType == other.runtimeType &&
          courseName == other.courseName &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          sks == other.sks &&
          lecturer == other.lecturer &&
          location == other.location;

  @override
  int get hashCode =>
      Object.hash(courseName, startTime, endTime, sks, lecturer, location);
}

/// Aggregated home screen data returned from the repository.
class HomeEntity {
  const HomeEntity({
    required this.userName,
    required this.avatarUrl,
    this.nextClass,
    required this.scheduleItems,
    required this.sksTaken,
    required this.todayClassCount,
    required this.semester,
    required this.studyProgram,
    required this.gpaGanjil,
    required this.gpaGenap,
  });

  final String userName;
  final String avatarUrl;
  final NextClassEntity? nextClass;
  final List<ScheduleItemEntity> scheduleItems;
  final int sksTaken;
  final int todayClassCount;
  final String semester;
  final String studyProgram;
  final double gpaGanjil;
  final double gpaGenap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeEntity &&
          runtimeType == other.runtimeType &&
          userName == other.userName &&
          avatarUrl == other.avatarUrl &&
          nextClass == other.nextClass &&
          scheduleItems == other.scheduleItems &&
          sksTaken == other.sksTaken &&
          todayClassCount == other.todayClassCount &&
          semester == other.semester &&
          studyProgram == other.studyProgram &&
          gpaGanjil == other.gpaGanjil &&
          gpaGenap == other.gpaGenap;

  @override
  int get hashCode => Object.hash(
    userName,
    avatarUrl,
    nextClass,
    scheduleItems,
    sksTaken,
    todayClassCount,
    semester,
    studyProgram,
    gpaGanjil,
    gpaGenap,
  );
}
