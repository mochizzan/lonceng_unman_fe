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
    this.isRead = false,
    this.sourceIndex = 0,
    this.scheduledId,
    this.title,
    this.body,
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

  @HiveField(7)
  final int sourceIndex;

  @HiveField(8)
  final bool isRead;

  @HiveField(9)
  final int? scheduledId;

  @HiveField(10)
  final String? title;

  @HiveField(11)
  final String? body;

  NotificationDeliveredModel copyWith({
    int? id,
    String? courseName,
    String? dayOfWeek,
    DateTime? classTime,
    DateTime? deliveredAt,
    String? room,
    String? lecturer,
    int? sourceIndex,
    bool? isRead,
    int? scheduledId,
    String? title,
    String? body,
  }) {
    return NotificationDeliveredModel(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      classTime: classTime ?? this.classTime,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      room: room ?? this.room,
      lecturer: lecturer ?? this.lecturer,
      sourceIndex: sourceIndex ?? this.sourceIndex,
      isRead: isRead ?? this.isRead,
      scheduledId: scheduledId ?? this.scheduledId,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

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
      sourceIndex: entity.source.index,
      isRead: entity.isRead,
      scheduledId: entity.scheduledId,
      title: entity.title,
      body: entity.body,
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
      source: NotificationSource
          .values[sourceIndex.clamp(0, NotificationSource.values.length - 1)],
      isRead: isRead,
      scheduledId: scheduledId,
      title: title,
      body: body,
    );
  }
}
