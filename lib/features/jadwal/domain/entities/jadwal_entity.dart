// jadwal - Entity
//
// Domain-layer entity representing the weekly schedule (jadwal) data.
// Follows Clean Architecture: domain layer has no framework dependencies.

/// Status of a schedule item (class session).
enum JadwalScheduleStatus {
  /// The class is currently in progress.
  ongoing,

  /// The class is upcoming (starts later today).
  upcoming,

  /// The class already finished.
  completed,
}

/// A single class session in the weekly schedule timeline.
class JadwalScheduleItem {
  const JadwalScheduleItem({
    required this.courseName,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.sks,
    required this.status,
    this.lecturer,
  });

  final String courseName;
  final DateTime startTime;
  final DateTime endTime;
  final String? lecturer;
  final String room;
  final String sks;
  final JadwalScheduleStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalScheduleItem &&
          runtimeType == other.runtimeType &&
          courseName == other.courseName &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          lecturer == other.lecturer &&
          room == other.room &&
          sks == other.sks &&
          status == other.status;

  @override
  int get hashCode =>
      Object.hash(courseName, startTime, endTime, lecturer, room, sks, status);
}

/// Aggregated weekly schedule data returned from the repository.
class JadwalEntity {
  const JadwalEntity({
    required this.selectedDay,
    required this.days,
    required this.scheduleItems,
  });

  final String selectedDay;
  final List<String> days;
  final List<JadwalScheduleItem> scheduleItems;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalEntity &&
          runtimeType == other.runtimeType &&
          selectedDay == other.selectedDay &&
          days == other.days &&
          scheduleItems == other.scheduleItems;

  @override
  int get hashCode => Object.hash(selectedDay, days, scheduleItems);
}
