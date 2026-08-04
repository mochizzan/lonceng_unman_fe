import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

part 'scheduled_notification_model.g.dart';

/// Hive-annotated model for scheduled notification persistence.
///
/// Stores notification data in a Hive box. Converts to/from domain entity
/// via [toEntity] and [fromEntity].
@HiveType(typeId: 0)
class ScheduledNotificationModel extends HiveObject {
  ScheduledNotificationModel({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.classTime,
    required this.reminderOffset,
    required this.room,
    this.lecturer,
    required this.isActive,
  });

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String courseName;

  @HiveField(2)
  final String dayOfWeek;

  @HiveField(3)
  final DateTime classTime;

  @HiveField(4)
  final int reminderOffset;

  @HiveField(5)
  final String room;

  @HiveField(6)
  final String? lecturer;

  @HiveField(7)
  final bool isActive;

  /// Convert to domain entity.
  ScheduledNotificationEntity toEntity() {
    return ScheduledNotificationEntity(
      id: id,
      courseName: courseName,
      dayOfWeek: dayOfWeek,
      classTime: classTime,
      reminderOffset: reminderOffset,
      room: room,
      lecturer: lecturer,
      isActive: isActive,
    );
  }

  /// Create from domain entity.
  factory ScheduledNotificationModel.fromEntity(
    ScheduledNotificationEntity entity,
  ) {
    return ScheduledNotificationModel(
      id: entity.id,
      courseName: entity.courseName,
      dayOfWeek: entity.dayOfWeek,
      classTime: entity.classTime,
      reminderOffset: entity.reminderOffset,
      room: entity.room,
      lecturer: entity.lecturer,
      isActive: entity.isActive,
    );
  }
}
