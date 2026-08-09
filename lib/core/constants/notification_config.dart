// lib/core/constants/notification_config.dart
/// Centralized notification configuration.
///
/// ALL notification-related constants live here — channel definitions,
/// Hive persistence keys, default values, and UI strings.
/// No notification value should be hardcoded anywhere else in the codebase.
///
/// Architecture:
/// - [NotificationChannel] enum carries per-channel metadata (ID, name, description, importance)
/// - [NotificationConfig] holds shared constants (icon, color, Hive keys, defaults)
/// - Adding a new channel = adding one enum value. Zero other files to touch.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Typed notification channel registry.
///
/// Each enum value IS the channel — its [id], [name], [description], and
/// [importance] live on the enum itself. No separate map, no duplication.
///
/// To add a new channel:
/// 1. Add an enum value with its metadata
/// 2. Done — [NotificationService] auto-creates it at init.
enum NotificationChannel {
  /// Pengingat jadwal kuliah (5-60 min before class).
  classReminders(
    id: 'lonceng_unman_class_reminders',
    name: 'Pengingat Kelas',
    description: 'Notifikasi pengingat sebelum kelas dimulai',
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
  );

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    this.enableVibration = false,
    this.enableLights = false,
  });

  /// Android channel ID (unique, used by system).
  final String id;

  /// Human-readable channel name (shown in Android Settings).
  final String name;

  /// Channel description (shown in Android Settings).
  final String description;

  /// Notification importance level.
  final Importance importance;

  /// Whether vibration is enabled on this channel.
  final bool enableVibration;

  /// Whether LED lights are enabled on this channel.
  final bool enableLights;
}

/// Shared notification constants (icon, color, Hive keys, defaults).
///
/// Per-channel metadata lives on [NotificationChannel] enum — not here.
abstract final class NotificationConfig {
  // ─── Notification Icon & Color ────────────────────────────
  /// Android notification small icon (drawable resource reference).
  static const String icon = '@drawable/ic_notification';

  /// Accent color for notifications (matches DESIGN.md seed color).
  /// Value: #FFC107 (Amber).
  static const int accentColorValue = 0xFFFFC107;

  // ─── Hive Box Names ───────────────────────────────────────
  /// Box storing scheduled notification entries.
  static const String scheduledNotificationsBox = 'scheduled_notifications';

  /// Box storing notification settings (e.g. reminder interval, channel toggles).
  static const String notificationSettingsBox = 'notification_settings';

  // ─── Hive Settings Keys ───────────────────────────────────
  /// Key for the reminder interval setting (stored as int, in minutes).
  static const String reminderIntervalKey = 'reminder_interval_minutes';

  // ─── Reminder Defaults ────────────────────────────────────
  /// Default reminder offset in minutes before class starts.
  static const int defaultReminderMinutes = 5;

  /// Available reminder interval options (in minutes).
  static const List<int> reminderOptions = [5, 10, 15, 30, 60];
}
