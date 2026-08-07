// jadwal - Entity
//
// Domain-layer entity representing the weekly schedule (jadwal) data.
// Follows Clean Architecture: domain layer has no framework dependencies.

import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';

/// Aggregated weekly schedule data returned from the repository.
class JadwalEntity {
  const JadwalEntity({
    required this.selectedDay,
    required this.days,
    required this.scheduleItems,
  });

  final String selectedDay;
  final List<String> days;
  final List<ScheduleItemEntity> scheduleItems;

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
