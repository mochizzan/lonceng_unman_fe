import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/utils/day_name_mapper.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Domain service that orchestrates notification scheduling.
///
/// Reads schedule data from [JadwalEntity], computes trigger times using
/// [DayNameMapper], and delegates to [NotificationRepository] for persistence
/// and [NotificationService] for platform alarm registration.
///
/// This is NOT a usecase — it orchestrates multiple repository and service calls.
class NotificationScheduler {
  NotificationScheduler({
    required this._repository,
    required this._notificationService,
  });

  final NotificationRepository _repository;
  final NotificationService _notificationService;

  /// Schedule notifications for all classes in [jadwal].
  ///
  /// For each [ScheduleItemEntity]:
  /// 1. Computes the next occurrence of the day-of-week
  /// 2. Combines with class start time minus reminder offset
  /// 3. Registers alarm via flutter_local_notifications
  /// 4. Persists to Hive via repository
  Future<void> scheduleForDay(JadwalEntity jadwal) async {
    // TODO: Implement per-day notification scheduling.
    // Currently skipped when selectedDay is 'Semua' (all-days view)
    // because DayNameMapper only handles specific day names (Senin-Minggu).
    // When 'Semua' is selected, we should iterate each scheduleItem's actual
    // dayOfWeek and schedule notifications per real day.
    if (jadwal.selectedDay == 'Semua') {
      developer.log(
        'Skipping notification scheduling — selectedDay is Semua (all-days view)',
        name: 'NotificationScheduler',
      );
      return;
    }

    final reminderOffset = _repository.getReminderInterval();
    final entities = <ScheduledNotificationEntity>[];

    for (final item in jadwal.scheduleItems) {
      final entity = ScheduledNotificationEntity(
        id: ScheduledNotificationEntity.computeId(
          item.courseName,
          jadwal.selectedDay,
          item.startTime.hour,
        ),
        courseName: item.courseName,
        dayOfWeek: jadwal.selectedDay,
        classTime: item.startTime,
        reminderOffset: reminderOffset,
        room: item.room,
        lecturer: item.lecturer,
        isActive: true,
      );

      entities.add(entity);

      // Schedule the alarm
      await _scheduleAlarm(entity);
    }

    // Persist all entities
    await _repository.saveAll(entities);

    developer.log(
      'Scheduled ${entities.length} notifications for ${jadwal.selectedDay}',
      name: 'NotificationScheduler',
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
  ///
  /// Called when the user changes the reminder interval in settings.
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {
    final allNotifications = await _repository.getAll();

    // Cancel all existing alarms
    await _notificationService.cancelAll();

    // Re-schedule each active notification with new offset
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

  // TODO: When selectedDay is 'Semua', each ScheduleItemEntity should carry
  // its own dayOfWeek so _scheduleAlarm can compute the correct next occurrence.
  // Currently all items share jadwal.selectedDay which breaks for 'Semua'.

  /// Compute the trigger DateTime and schedule the alarm.
  Future<void> _scheduleAlarm(ScheduledNotificationEntity entity) async {
    if (!entity.isActive) return;

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

    // Defensive timezone conversion — fallback to device time if tz data unavailable
    tz.TZDateTime tzTrigger;
    try {
      tzTrigger = tz.TZDateTime.from(triggerTime, tz.local);
    } catch (e) {
      developer.log(
        'WARNING: Timezone fallback — tz data may be missing or invalid: $e',
        name: 'NotificationScheduler',
      );
      tzTrigger = tz.TZDateTime(
        tz.local,
        triggerTime.year,
        triggerTime.month,
        triggerTime.day,
        triggerTime.hour,
        triggerTime.minute,
      );
    }

    // Check exact alarm capability (Android 12+)
    final canUseExact = await _notificationService
        .canScheduleExactNotifications();
    if (!canUseExact) {
      developer.log(
        'Exact notifications not available — scheduling inexact for ${entity.courseName}',
        name: 'NotificationScheduler',
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
