import 'package:flutter/foundation.dart' show debugPrint;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/utils/day_name_mapper.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_delivered_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/core/utils/delivered_id.dart';
import 'package:timezone/timezone.dart' as tz;

/// Domain service that orchestrates notification scheduling.
///
/// Reads schedule data from [JadwalEntity], computes trigger times using
/// [DayNameMapper], and delegates to [NotificationRepository] for persistence
/// and [NotificationService] for platform alarm registration.
///
/// Optimistic history: after each alarm is scheduled, a
/// [NotificationDeliveredEntity] with `deliveredAt = trigger` is saved via
/// [_deliveredRepository] (if available). Future items are hidden in UI via
/// `visibleDelivered` filter.
class NotificationScheduler {
  NotificationScheduler({
    required this._repository,
    required this._notificationService,
    NotificationDeliveredRepository? deliveredRepository,
  }) : _deliveredRepository = deliveredRepository;

  final NotificationRepository _repository;
  final NotificationService _notificationService;
  final NotificationDeliveredRepository? _deliveredRepository;

  /// Compute the trigger DateTime for [entity] (shared helper for scheduler + reconciliation).
  tz.TZDateTime computeTrigger(ScheduledNotificationEntity entity) {
    final nextOccurrence = DayNameMapper.nextOccurrence(entity.dayOfWeek);
    final classDateTime = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
      entity.classTime.hour,
      entity.classTime.minute,
    );
    final triggerTime = classDateTime.subtract(
      Duration(minutes: entity.reminderOffset),
    );
    try {
      return tz.TZDateTime.from(triggerTime, tz.local);
    } catch (e) {
      debugPrint('[NotificationScheduler] WARNING: Timezone fallback — $e');
      return tz.TZDateTime(
        tz.local,
        triggerTime.year,
        triggerTime.month,
        triggerTime.day,
        triggerTime.hour,
        triggerTime.minute,
      );
    }
  }

  /// Schedule notifications for all classes in [jadwal].
  Future<void> scheduleForDay(JadwalEntity jadwal) async {
    await cancelAll();

    final reminderOffset = _repository.getReminderInterval();
    final entities = <ScheduledNotificationEntity>[];

    for (final item in jadwal.scheduleItems) {
      final dayOfWeek = item.dayOfWeek.isNotEmpty
          ? item.dayOfWeek
          : jadwal.selectedDay;

      final entity = ScheduledNotificationEntity(
        id: ScheduledNotificationEntity.computeId(
          item.courseName,
          dayOfWeek,
          item.startTime.hour,
        ),
        courseName: item.courseName,
        dayOfWeek: dayOfWeek,
        classTime: item.startTime,
        reminderOffset: reminderOffset,
        room: item.room,
        lecturer: item.lecturer,
        isActive: true,
      );

      entities.add(entity);
      await _scheduleAlarm(entity);
    }

    await _repository.saveAll(entities);

    debugPrint(
      '[NotificationScheduler] scheduleForDay() OK: ${entities.length} notifications scheduled',
    );
  }

  /// Schedule notifications for ALL classes across ALL days.
  Future<void> scheduleAllDays(List<ScheduleItemEntity> items) async {
    debugPrint(
      '[NotificationScheduler] scheduleAllDays() START — ${items.length} items',
    );

    await cancelAll();

    final reminderOffset = _repository.getReminderInterval();
    final entities = <ScheduledNotificationEntity>[];

    for (final item in items) {
      if (item.dayOfWeek.isEmpty) {
        debugPrint(
          '[NotificationScheduler] SKIP: ${item.courseName} has no dayOfWeek',
        );
        continue;
      }

      final entity = ScheduledNotificationEntity(
        id: ScheduledNotificationEntity.computeId(
          item.courseName,
          item.dayOfWeek,
          item.startTime.hour,
        ),
        courseName: item.courseName,
        dayOfWeek: item.dayOfWeek,
        classTime: item.startTime,
        reminderOffset: reminderOffset,
        room: item.room,
        lecturer: item.lecturer,
        isActive: true,
      );

      entities.add(entity);
      await _scheduleAlarm(entity);
    }

    await _repository.saveAll(entities);

    debugPrint(
      '[NotificationScheduler] scheduleAllDays() OK: ${entities.length} notifications scheduled',
    );
  }

  /// Schedule a single notification alarm for [entity].
  Future<void> scheduleSingle(ScheduledNotificationEntity entity) async {
    await _scheduleAlarm(entity);
  }

  /// Cancel a single notification alarm for [entity].
  Future<void> cancelSingle(ScheduledNotificationEntity entity) async {
    await _notificationService.cancel(entity.id);
  }

  /// Cancel all scheduled notification alarms.
  Future<void> cancelAll() async {
    await _notificationService.cancelAll();
    await _repository.deleteAll();
  }

  /// Reschedule all active notifications with a new reminder offset.
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {
    final allNotifications = await _repository.getAll();

    await _notificationService.cancelAll();

    for (final entity in allNotifications) {
      final updated = ScheduledNotificationEntity(
        id: entity.id,
        courseName: entity.courseName,
        dayOfWeek: entity.dayOfWeek,
        classTime: entity.classTime,
        reminderOffset: newOffsetMinutes,
        room: entity.room,
        lecturer: entity.lecturer,
        isActive: entity.isActive,
      );

      await _repository.save(updated);

      if (updated.isActive) {
        await _scheduleAlarm(updated);
      }
    }
  }

  Future<void> _saveOptimistic(
    ScheduledNotificationEntity entity,
    tz.TZDateTime tzTrigger,
  ) async {
    final repo = _deliveredRepository;
    if (repo == null) return;
    final triggerDt = DateTime(
      tzTrigger.year,
      tzTrigger.month,
      tzTrigger.day,
      tzTrigger.hour,
      tzTrigger.minute,
    );
    final deliveredId = deliveredIdFor(entity.id, triggerDt);
    if (repo.containsKey(deliveredId)) return;
    try {
      await repo.save(
        NotificationDeliveredEntity(
          id: deliveredId,
          courseName: entity.courseName,
          dayOfWeek: entity.dayOfWeek,
          classTime: entity.classTime,
          deliveredAt: triggerDt,
          room: entity.room,
          lecturer: entity.lecturer,
          isRead: false,
          source: NotificationSource.classReminder,
          scheduledId: entity.id,
        ),
      );
    } catch (e) {
      debugPrint('[NotificationScheduler] optimistic save failed: $e');
    }
  }

  /// Compute the trigger DateTime and schedule the alarm.
  Future<void> _scheduleAlarm(ScheduledNotificationEntity entity) async {
    if (!entity.isActive) return;

    final tzTrigger = computeTrigger(entity);

    final canUseExact = await _notificationService
        .canScheduleExactNotifications();
    if (!canUseExact) {
      debugPrint(
        '[NotificationScheduler] Exact notifications not available — scheduling inexact for ${entity.courseName}',
      );
    }

    await _notificationService.schedule(
      id: entity.id,
      title: entity.courseName,
      body: _buildBody(entity),
      channel: NotificationChannel.classReminders,
      scheduledDate: tzTrigger,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: canUseExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    await _saveOptimistic(entity, tzTrigger);
  }

  /// Build notification body text.
  String _buildBody(ScheduledNotificationEntity entity) {
    final timeStr =
        '${entity.classTime.hour.toString().padLeft(2, '0')}:'
        '${entity.classTime.minute.toString().padLeft(2, '0')}';
    final parts = <String>[entity.room, timeStr];
    if (entity.lecturer != null && entity.lecturer!.isNotEmpty) {
      parts.add(entity.lecturer!);
    }
    return parts.join(' • ');
  }
}
