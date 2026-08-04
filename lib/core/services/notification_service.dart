// lib/core/services/notification_service.dart
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Thin wrapper around flutter_local_notifications plugin.
///
/// Handles initialization, channel creation, and alarm scheduling.
/// Lives in core/services/ (not feature layer) because it wraps a platform service,
/// mirroring the existing FcmService pattern.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'lonceng_unman_class_reminders';
  static const _channelName = 'Pengingat Kelas';
  static const _channelDescription =
      'Notifikasi pengingat sebelum kelas dimulai';

  /// Initialize the plugin, create notification channel, and request permissions.
  ///
  /// Must be called once at app startup, after Hive is open.
  /// Handles timezone init failure gracefully — falls back to device local time.
  Future<void> initialize() async {
    // Initialize timezone database with defensive fallback
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);
    } catch (e) {
      // Timezone data unavailable — use device local time as fallback
      // Notifications may fire at slightly wrong time during DST transitions
      developer.log(
        'Timezone init failed, using device time: $e',
        name: 'NotificationService',
      );
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Create notification channel (Android 8.0+)
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }

    developer.log(
      'NotificationService initialized',
      name: 'NotificationService',
    );
  }

  /// Schedule a notification at [scheduledDate] (timezone-aware).
  ///
  /// [id] must be non-negative and unique per notification.
  /// [scheduledDate] is a TZDateTime for timezone-correct firing.
  /// [matchDateTimeComponents] is optional — pass [DateTimeComponents.dayOfWeekAndTime]
  /// for weekly recurring notifications.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: Color(0xFFFFC107), // Amber accent
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );

    developer.log(
      'Scheduled notification #$id: $title at $scheduledDate',
      name: 'NotificationService',
    );
  }

  /// Cancel a single notification by ID.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
    developer.log('Cancelled notification #$id', name: 'NotificationService');
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    developer.log('Cancelled all notifications', name: 'NotificationService');
  }

  /// Check if notifications are enabled on this device.
  ///
  /// On Android 13+ (API 33+), checks POST_NOTIFICATIONS permission.
  /// On older Android and iOS, returns true by default.
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    // iOS: permission is requested on init; assume enabled if we got here
    return true;
  }

  /// Check if exact notifications can be scheduled (Android 12+).
  ///
  /// On Android 12+ (API 31+), SCHEDULE_EXACT_ALARM is a special permission
  /// that users can revoke. If denied, we fall back to inexact scheduling.
  Future<bool> canScheduleExactNotifications() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.canScheduleExactNotifications() ?? true;
    }
    return true; // iOS doesn't have this restriction
  }
}
