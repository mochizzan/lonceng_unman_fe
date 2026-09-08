import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

/// No-op subclass used when NotificationService fails to initialize.
/// Extends real class to maintain type safety in DI.
class NotificationSchedulerNoop extends NotificationScheduler {
  NotificationSchedulerNoop()
    : super(
        repository: _NoOpRepository(),
        notificationService: _NoOpNotificationService(),
      );

  @override
  Future<void> scheduleForDay(JadwalEntity jadwal) async {}

  @override
  Future<void> scheduleAllDays(List<ScheduleItemEntity> items) async {}

  @override
  Future<void> scheduleSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {}

  @override
  Future<int> restoreAll() async => 0;

  @override
  tz.TZDateTime computeTrigger(ScheduledNotificationEntity entity) {
    throw UnimplementedError('computeTrigger not available in Noop');
  }
}

/// Minimal no-op repository for constructor compliance.
class _NoOpRepository implements NotificationRepository {
  @override
  Future<List<ScheduledNotificationEntity>> getAll() async => [];
  @override
  Future<ScheduledNotificationEntity?> getById(int id) async => null;
  @override
  Future<void> save(ScheduledNotificationEntity notification) async {}
  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  int getReminderInterval() => 5;
  @override
  void setReminderInterval(int minutes) {}
}

/// Minimal no-op notification service for constructor compliance.
class _NoOpNotificationService extends NotificationService {
  _NoOpNotificationService() : super();
}
