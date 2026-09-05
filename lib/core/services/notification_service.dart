// lib/core/services/notification_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Background isolate entry point for notification actions (Android).
///
/// `flutter_local_notifications` delivers taps on notification *actions*
/// when the app is in background/terminated via this callback. It MUST be
/// top-level and annotated `@pragma('vm:entry-point')` so the tree-shaker
/// keeps it. We keep it minimal: just log. The real handling is forced to
/// foreground via `showsUserInterface:true` on actions (see controller), so
/// the foreground `onDidReceiveNotificationResponse` will fire after the app
/// is brought forward. This handler exists only so the OS doesn't drop the
/// intent on Android 14+ / OEMs that require a background handler to be
/// registered at all.
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  debugPrint(
    '[NotificationService-BG] onDidReceiveBackgroundNotificationResponse '
    'id=${response.id} actionId=${response.actionId} payload=${response.payload}',
  );
}

/// Thin wrapper around flutter_local_notifications plugin.
///
/// Handles initialization, channel creation, and alarm scheduling.
/// Lives in core/services/ (not feature layer) because it wraps a platform service,
/// mirroring the existing FcmService pattern.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// External handler for notification tap / action responses.
  /// Set by DI wiring (e.g. DownloadNotificationController). Invoked alongside
  /// internal handling so features can react without owning initialization.
  void Function(NotificationResponse response)? _externalResponseHandler;

  void setExternalResponseHandler(
    void Function(NotificationResponse response)? handler,
  ) {
    _externalResponseHandler = handler;
  }

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

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          '[NotificationService] onDidReceiveNotificationResponse '
          'id=${response.id} actionId=${response.actionId} payload=${response.payload}',
        );
        // Forward to external handler (e.g. download controller).
        try {
          _externalResponseHandler?.call(response);
        } catch (e) {
          debugPrint('[NotificationService] External handler error: $e');
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

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

  /// Show a simple notification immediately (no schedule).
  ///
  /// Thin wrapper over [_plugin.show] using channel defaults.
  /// Prefer this over calling plugin directly so channels stay centralized.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationChannel channel,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
    List<AndroidNotificationAction>? actions,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      icon: NotificationConfig.icon,
      color: const Color(NotificationConfig.accentColorValue),
      enableVibration: channel.enableVibration,
      enableLights: channel.enableLights,
      ongoing: ongoing,
      autoCancel: autoCancel,
      actions: actions,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
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
