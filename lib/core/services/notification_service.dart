// lib/core/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
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

  /// Build [NotificationDetails] for a given [channel].
  static NotificationDetails _detailsFor(NotificationChannel channel) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: NotificationConfig.icon,
          color: const Color(NotificationConfig.accentColorValue),
          enableVibration: channel.enableVibration,
          enableLights: channel.enableLights,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  /// Initialize the plugin, create ALL notification channels, and request permissions.
  ///
  /// Must be called once at app startup, after Hive is open.
  /// Iterates [NotificationChannel.values] to create every channel —
  /// adding a new channel = adding one enum value, zero changes here.
  Future<void> initialize() async {
    // Initialize timezone database with defensive fallback
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);
    } catch (e) {
      debugPrint(
        '[NotificationService] Timezone init failed, using device time: $e',
      );
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      NotificationConfig.icon,
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

    // Create ALL notification channels (Android 8.0+)
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      for (final channel in NotificationChannel.values) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.name,
            description: channel.description,
            importance: channel.importance,
            enableVibration: channel.enableVibration,
            enableLights: channel.enableLights,
          ),
        );
      }
    }

    debugPrint(
      '[NotificationService] Initialized with ${NotificationChannel.values.length} channels',
    );
  }

  /// Schedule a notification at [scheduledDate] (timezone-aware).
  ///
  /// [id] must be non-negative and unique per notification.
  /// [channel] determines which Android channel to use.
  /// [matchDateTimeComponents] is optional — pass [DateTimeComponents.dayOfWeekAndTime]
  /// for weekly recurring notifications.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required NotificationChannel channel,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.exactAllowWhileIdle,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _detailsFor(channel),
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );

      debugPrint(
        '[NotificationService] Scheduled [#${channel.id}] #$id: $title at $scheduledDate',
      );
    } on Exception catch (e) {
      debugPrint(
        '[NotificationService] WARNING: Failed to schedule notification — timezone data may be missing or invalid: $e',
      );
    }
  }

  /// Cancel a single notification by ID.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
    debugPrint('[NotificationService] Cancelled notification #$id');
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] Cancelled all notifications');
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
    return true;
  }

  /// Check current notification permission status without prompting.
  /// Returns true if notifications are already enabled.
  Future<bool> checkPermissionStatus() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    // Non-Android platforms: treat as granted.
    return true;
  }

  /// Request notification permission (required for Android 13+).
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    // Other platforms (web, Linux, etc.) – treat as granted.
    return true;
  }
}
