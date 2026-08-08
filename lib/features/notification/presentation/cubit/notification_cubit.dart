import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

/// Cubit managing notification scheduling state.
///
/// This is the first Cubit in the codebase (all existing features use Bloc).
/// Chosen because notification state is simple (status + list + interval)
/// and flutter_local_notifications callbacks need direct method calls.
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required this._scheduler,
    required this._repository,
    required this._notificationService,
  }) : super(const NotificationState());

  final NotificationScheduler _scheduler;
  final NotificationRepository _repository;
  final NotificationService _notificationService;

  /// Check if notification permission is granted.
  /// Emits [notificationPermissionDenied] on the state if denied.
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> checkPermission() async {
    debugPrint('[NOTIF] checkPermission() START');
    final enabled = await _notificationService.requestPermission();
    debugPrint('[NOTIF]   OK: permission enabled=$enabled');
    emit(state.copyWith(notificationPermissionDenied: !enabled));
    return enabled;
  }

  /// Load all scheduled notifications and current reminder interval.
  Future<void> loadNotifications() async {
    debugPrint('[NOTIF] loadNotifications() START');
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      await checkPermission();
      final notifications = await _repository.getAll();
      final interval = _repository.getReminderInterval();
      debugPrint('[NOTIF]   OK: loaded ${notifications.length} notifikasi');
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: notifications,
          reminderIntervalMinutes: interval,
          clearErrorMessage: true,
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

  /// Schedule notifications for all classes in [jadwal].
  ///
  /// Called when JadwalBloc emits JadwalLoaded.
  /// Checks notification permission first — if denied, emits error and returns
  /// early to avoid scheduling notifications that will never display.
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
      debugPrint(
        '[NOTIF]   OK: ${notifications.length} notifikasi dijadwalkan',
      );
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: notifications,
          clearErrorMessage: true,
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
      debugPrint('[NOTIF]   OK: toggled id=$id -> active=${toggled.isActive}');
      emit(
        state.copyWith(notifications: notifications, clearErrorMessage: true),
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
      debugPrint('[NOTIF]   OK: interval diupdate ke ${minutes}m');
      emit(
        state.copyWith(
          reminderIntervalMinutes: minutes,
          notifications: notifications,
          clearErrorMessage: true,
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
