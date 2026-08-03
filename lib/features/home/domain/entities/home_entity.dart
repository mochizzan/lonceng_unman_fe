// home - Entity
//
// Domain-layer entity representing the aggregated home screen data.
// Follows Clean Architecture: domain layer has no framework dependencies.

/// Status of a schedule item (class session).
enum ScheduleStatus {
  /// The class is currently in progress.
  ongoing,

  /// The class is upcoming (starts later today).
  upcoming,

  /// The class already finished.
  completed,
}

/// A single schedule (class session) on the home screen timeline.
class ScheduleItemEntity {
  const ScheduleItemEntity({
    required this.courseName,
    required this.room,
    required this.startTime,
    required this.endTime,
    this.lecturer,
    this.group,
    this.status = ScheduleStatus.upcoming,
  });

  final String courseName;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final String? lecturer;
  final String? group;
  final ScheduleStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleItemEntity &&
          runtimeType == other.runtimeType &&
          courseName == other.courseName &&
          room == other.room &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          lecturer == other.lecturer &&
          group == other.group &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    courseName,
    room,
    startTime,
    endTime,
    lecturer,
    group,
    status,
  );
}

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
    required this.nextClass,
    required this.scheduleItems,
    required this.sksTaken,
    required this.sksTotal,
    required this.todayClassCount,
    required this.semester,
    required this.studyProgram,
    required this.gpa,
  });

  final String userName;
  final String avatarUrl;
  final NextClassEntity nextClass;
  final List<ScheduleItemEntity> scheduleItems;
  final int sksTaken;
  final int sksTotal;
  final int todayClassCount;
  final String semester;
  final String studyProgram;
  final double gpa;

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
          sksTotal == other.sksTotal &&
          todayClassCount == other.todayClassCount &&
          semester == other.semester &&
          studyProgram == other.studyProgram &&
          gpa == other.gpa;

  @override
  int get hashCode => Object.hash(
    userName,
    avatarUrl,
    nextClass,
    scheduleItems,
    sksTaken,
    sksTotal,
    todayClassCount,
    semester,
    studyProgram,
    gpa,
  );
}
