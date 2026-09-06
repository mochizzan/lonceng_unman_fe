import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/core/utils/day_name_mapper.dart';
import 'package:lonceng_unman_fe/core/utils/delivered_id.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_delivered_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

/// Cubit managing notification scheduling state.
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required this._scheduler,
    required this._repository,
    required this._notificationService,
    NotificationDeliveredRepository? deliveredRepository,
  }) : _deliveredRepository = deliveredRepository,
       super(const NotificationState());

  final NotificationScheduler _scheduler;
  final NotificationRepository _repository;
  final NotificationService _notificationService;
  final NotificationDeliveredRepository? _deliveredRepository;

  /// Check if notification permission is granted.
  Future<bool> checkPermission() async {
    debugPrint('[NOTIF] checkPermission() START');
    final currentStatus = await _notificationService.checkPermissionStatus();
    if (currentStatus) {
      debugPrint('[NOTIF]   OK: permission already granted');
      emit(state.copyWith(notificationPermissionDenied: false));
      return true;
    }
    final enabled = await _notificationService.requestPermission();
    debugPrint('[NOTIF]   OK: permission enabled=$enabled');
    emit(state.copyWith(notificationPermissionDenied: !enabled));
    return enabled;
  }

  Future<List<NotificationDeliveredEntity>> _loadDelivered() async {
    final repo = _deliveredRepository;
    if (repo == null) return [];
    try {
      return await repo.getAll();
    } catch (e) {
      debugPrint('[NOTIF] _loadDelivered failed: $e');
      return [];
    }
  }

  /// Load all scheduled notifications and delivered history.
  Future<void> loadNotifications() async {
    debugPrint('[NOTIF] loadNotifications() START');
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      await checkPermission();
      final notifications = await _repository.getAll();
      final interval = _repository.getReminderInterval();
      final delivered = await _loadDelivered();
      debugPrint(
        '[NOTIF]   OK: loaded ${notifications.length} notifikasi, ${delivered.length} delivered',
      );
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: notifications,
          delivered: delivered,
          reminderIntervalMinutes: interval,
          clearErrorMessage: true,
          historyViewed: false,
        ),
      );
    } catch (e) {
      debugPrint('[NOTIF] loadNotifications() CATCH: $e');
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Refresh delivered list only.
  Future<void> loadDelivered() async {
    final delivered = await _loadDelivered();
    emit(state.copyWith(delivered: delivered));
  }

  /// Reconciliation: generate missing weekly occurrences per scheduledId.
  Future<void> reconcileDelivered() async {
    final repo = _deliveredRepository;
    if (repo == null) return;
    try {
      final scheduled = await _repository.getAll();
      if (scheduled.isEmpty) return;
      final deliveredAll = await repo.getAll();
      final now = DateTime.now();
      var created = 0;
      for (final s in scheduled) {
        try {
          if (!s.isActive) continue;
          // Compute next trigger via scheduler helper
          final tzTrigger = _scheduler.computeTrigger(s);
          final triggerDt = DateTime(
            tzTrigger.year,
            tzTrigger.month,
            tzTrigger.day,
            tzTrigger.hour,
            tzTrigger.minute,
          );
          final lastTrigger = now.isBefore(triggerDt)
              ? triggerDt.subtract(const Duration(days: 7))
              : triggerDt;

          final forId =
              deliveredAll.where((d) => d.scheduledId == s.id).toList()
                ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
          final lastSaved = forId.isEmpty ? null : forId.first.deliveredAt;
          DateTime startCursor;
          if (lastSaved == null) {
            // Backfill up to 12 weeks for fresh install
            startCursor = lastTrigger.subtract(const Duration(days: 7 * 11));
          } else {
            startCursor = lastSaved.add(const Duration(days: 7));
          }
          DateTime cursor = startCursor;
          // Legacy 7-field rows have scheduledId==null — ignored for grouping to avoid duplicate
          // Generate up to lastTrigger inclusive, but not future > now
          while (!cursor.isAfter(lastTrigger) && !cursor.isAfter(now)) {
            final deliveredId = deliveredIdFor(s.id, cursor);
            if (!repo.containsKey(deliveredId)) {
              await repo.save(
                NotificationDeliveredEntity(
                  id: deliveredId,
                  courseName: s.courseName,
                  dayOfWeek: s.dayOfWeek,
                  classTime: s.classTime,
                  deliveredAt: cursor,
                  room: s.room,
                  lecturer: s.lecturer,
                  isRead: false,
                  source: NotificationSource.classReminder,
                  scheduledId: s.id,
                ),
              );
              created++;
            }
            final next = cursor.add(const Duration(days: 7));
            if (next.isAfter(lastTrigger)) break;
            cursor = next;
          }
        } catch (e) {
          debugPrint('[reconcile] Skip ${s.courseName}: $e');
          continue;
        }
      }
      if (created > 0) {
        debugPrint('[NOTIF] reconcileDelivered created $created');
        final refreshed = await repo.getAll();
        emit(state.copyWith(delivered: refreshed));
      }
    } catch (e) {
      debugPrint('[NOTIF] reconcileDelivered failed: $e');
    }
  }

  Future<void> _emitDelivered() async {
    final delivered = await _loadDelivered();
    emit(state.copyWith(delivered: delivered));
  }

  Future<void> markAsRead(int id) async {
    final repo = _deliveredRepository;
    if (repo == null) return;
    await repo.markAsRead(id);
    await _emitDelivered();
  }

  Future<void> markAllRead() async {
    final repo = _deliveredRepository;
    if (repo == null) return;
    await repo.markAllRead();
    await _emitDelivered();
  }

  Future<void> deleteDelivered(int id) async {
    final repo = _deliveredRepository;
    if (repo == null) return;
    await repo.delete(id);
    await _emitDelivered();
  }

  Future<void> deleteAllDelivered() async {
    final repo = _deliveredRepository;
    if (repo == null) return;
    await repo.deleteAll();
    await _emitDelivered();
  }

  /// Schedule notifications for ALL items across ALL days.
  Future<void> scheduleAll(List<ScheduleItemEntity> items) async {
    debugPrint('[NOTIF] scheduleAll() START — ${items.length} items');
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('[NOTIF]   ERROR: permission ditolak, batal menjadwalkan');
        emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: AppStrings.settingsNotificationPermissionDenied,
          ),
        );
        return;
      }
      await _scheduler.scheduleAllDays(items);
      final notifications = await _repository.getAll();
      final delivered = await _loadDelivered();
      debugPrint(
        '[NOTIF]   OK: ${notifications.length} notifikasi dijadwalkan',
      );
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: notifications,
          delivered: delivered,
          clearErrorMessage: true,
          historyViewed: false,
        ),
      );
    } catch (e) {
      debugPrint('[NOTIF] scheduleAll() CATCH: $e');
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Schedule notifications for all classes in [jadwal].
  Future<void> scheduleFromJadwal(JadwalEntity jadwal) async {
    debugPrint('[NOTIF] scheduleFromJadwal() START');
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('[NOTIF]   ERROR: permission ditolak, batal menjadwalkan');
        emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: AppStrings.settingsNotificationPermissionDenied,
          ),
        );
        return;
      }
      await _scheduler.scheduleForDay(jadwal);
      final notifications = await _repository.getAll();
      final delivered = await _loadDelivered();
      debugPrint(
        '[NOTIF]   OK: ${notifications.length} notifikasi dijadwalkan',
      );
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: notifications,
          delivered: delivered,
          clearErrorMessage: true,
          historyViewed: false,
        ),
      );
    } catch (e) {
      debugPrint('[NOTIF] scheduleFromJadwal() CATCH: $e');
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Toggle a specific notification on/off.
  Future<void> toggleNotification(int id) async {
    debugPrint('[NOTIF] toggleNotification($id) START');
    try {
      final existing = await _repository.getById(id);
      if (existing == null) {
        debugPrint('[NOTIF]   ERROR: notifikasi id=$id tidak ditemukan');
        return;
      }

      final toggled = ScheduledNotificationEntity(
        id: existing.id,
        courseName: existing.courseName,
        dayOfWeek: existing.dayOfWeek,
        classTime: existing.classTime,
        reminderOffset: existing.reminderOffset,
        room: existing.room,
        lecturer: existing.lecturer,
        isActive: !existing.isActive,
      );

      await _repository.save(toggled);

      if (toggled.isActive) {
        await _scheduler.scheduleSingle(toggled);
      } else {
        await _scheduler.cancelSingle(toggled);
      }

      final notifications = await _repository.getAll();
      final delivered = await _loadDelivered();
      debugPrint('[NOTIF]   OK: toggled id=$id -> active=${toggled.isActive}');
      emit(
        state.copyWith(
          notifications: notifications,
          delivered: delivered,
          clearErrorMessage: true,
          historyViewed: false,
        ),
      );
    } catch (e) {
      debugPrint('[NOTIF] toggleNotification($id) CATCH: $e');
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Update reminder interval and reschedule all active notifications.
  Future<void> updateReminderInterval(int minutes) async {
    debugPrint('[NOTIF] updateReminderInterval($minutes) START');
    try {
      _repository.setReminderInterval(minutes);
      await _scheduler.rescheduleAllWithNewOffset(minutes);
      final notifications = await _repository.getAll();
      final delivered = await _loadDelivered();
      debugPrint('[NOTIF]   OK: interval diupdate ke ${minutes}m');
      emit(
        state.copyWith(
          reminderIntervalMinutes: minutes,
          notifications: notifications,
          delivered: delivered,
          clearErrorMessage: true,
          historyViewed: false,
        ),
      );
    } catch (e) {
      debugPrint('[NOTIF] updateReminderInterval($minutes) CATCH: $e');
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Mark notification history as viewed (hides red dot).
  void markHistoryViewed() {
    if (!state.historyViewed) {
      emit(state.copyWith(historyViewed: true));
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    debugPrint('[NOTIF] cancelAll() START');
    try {
      await _scheduler.cancelAll();
      debugPrint('[NOTIF]   OK: semua notifikasi dibatalkan');
      emit(state.copyWith(notifications: [], clearErrorMessage: true));
    } catch (e) {
      debugPrint('[NOTIF] cancelAll() CATCH: $e');
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
