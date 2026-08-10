import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';

part 'notification_delivered_model.g.dart';

/// Hive model for [NotificationDeliveredEntity].
///
/// typeId: 1 (typeId 0 is used by ScheduledNotificationModel).
@HiveType(typeId: 1)
class NotificationDeliveredModel extends HiveObject {
  NotificationDeliveredModel({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.classTime,
    required this.deliveredAt,
    required this.room,
    this.lecturer,
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
  final DateTime deliveredAt;

  @HiveField(5)
  final String room;

  @HiveField(6)
  final String? lecturer;

  factory NotificationDeliveredModel.fromEntity(
    NotificationDeliveredEntity entity,
  ) {
    return NotificationDeliveredModel(
      id: entity.id,
      courseName: entity.courseName,
      dayOfWeek: entity.dayOfWeek,
      classTime: entity.classTime,
      deliveredAt: entity.deliveredAt,
      room: entity.room,
      lecturer: entity.lecturer,
    );
  }

  NotificationDeliveredEntity toEntity() {
    return NotificationDeliveredEntity(
      id: id,
      courseName: courseName,
      dayOfWeek: dayOfWeek,
      classTime: classTime,
      deliveredAt: deliveredAt,
      room: room,
      lecturer: lecturer,
    );
  }
}
