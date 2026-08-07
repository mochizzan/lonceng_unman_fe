import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Centralized helper for Android 13+ POST_NOTIFICATIONS runtime permission.
///
/// On Android 13+ (API 33), apps must request notification permission at
/// runtime before posting any notification.  On older Android versions and
/// iOS, notifications are enabled by default (iOS requests via its own
/// dialog during plugin init).
class NotificationPermission {
  const NotificationPermission._();

  /// Request the POST_NOTIFICATIONS permission.
  ///
  /// Returns `true` when granted (or on unsupported platforms).
  static Future<bool> request() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
