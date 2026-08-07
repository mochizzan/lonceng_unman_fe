// Shared schedule entities for the home and jadwal features.
//
// Contains the [ScheduleStatus] enum and [ScheduleItemEntity] used by
// both the home timeline and the weekly jadwal schedule.

/// Status of a schedule item (class session).
enum ScheduleStatus {
  /// The class is currently in progress.
  ongoing,

  /// The class is upcoming (starts later today).
  upcoming,

  /// The class already finished.
  completed,
}

/// A single class session in a schedule timeline.
///
/// Shared between the home screen timeline and the weekly jadwal schedule.
/// Optional fields [group] and [sks] are feature-specific extras.
class ScheduleItemEntity {
  final String courseName;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleStatus status;
  final String? lecturer;
  final String? group;
  final String? sks;

  const ScheduleItemEntity({
    required this.courseName,
    required this.room,
    required this.startTime,
    required this.endTime,
    this.status = ScheduleStatus.upcoming,
    this.lecturer,
    this.group,
    this.sks,
  });

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
          sks == other.sks &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    courseName,
    room,
    startTime,
    endTime,
    lecturer,
    group,
    sks,
    status,
  );
}
