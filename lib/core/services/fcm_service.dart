// lib/core/services/fcm_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import 'package:firebase_messaging/firebase_messaging.dart';

/// VAPID key for web push notifications.
/// Obtain from Firebase Console → Settings → Cloud Messaging → Web Push certificates.
const String _webVapidKey =
    'BEOyeFCQemJDI3vFVnrFP5meGjaMmnEFfnt0XaZUz5ciIT46x5EmdhPqGdxHiYX7U4dB12Q76K6E1mxwgu6s0rk';

/// Callback type for handling FCM notification interactions.
typedef FcmNotificationTapCallback = void Function(RemoteMessage message);

/// Service for managing Firebase Cloud Messaging.
///
/// Handles token lifecycle, permission requests, foreground/background
/// message listening, and notification tap handling.
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Controller for broadcasting foreground messages to listeners.
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of notification taps (app opened from background).
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Stream of messages received while the app is in the foreground.
  Stream<RemoteMessage> get onForegroundMessage => _messageController.stream;

  /// Current FCM registration token. Cached after first retrieval.
  String? _currentToken;

  /// Stream subscription for token refresh.
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Stream subscription for foreground messages.
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  /// Stream subscription for notification taps from background.
  StreamSubscription<RemoteMessage>? _backgroundTapSubscription;

  /// Callback for handling FCM notification taps (set by the app).
  FcmNotificationTapCallback? _onNotificationTap;

  /// Current FCM token (for debugging).
  String? get currentToken => _currentToken;

  /// Initialize FCM: get token, set up listeners.
  ///
  /// Permission is NOT requested here — it is deferred to the onboarding
  /// notification slide ("Izinkan" button) so the user is only prompted once
  /// during the first-time flow, not on every app launch.
  ///
  /// Call this after Firebase.initializeApp() in main().
  ///
  /// [onNotificationTap] is called when user taps a notification
  /// (both from terminated and background states).
  Future<void> initialize({
    FcmNotificationTapCallback? onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    debugPrint('[FCM] ============================================');
    debugPrint('[FCM] FcmService.initialize() START');

    try {
      // Step 1: Check notification authorization status.
      debugPrint('[FCM] Step 1: Checking notification settings...');
      final settings = await _messaging.getNotificationSettings();
      debugPrint('[FCM]   Authorization: ${settings.authorizationStatus}');
      debugPrint('[FCM]   Alert: ${settings.alert}');
      debugPrint('[FCM]   Badge: ${settings.badge}');
      debugPrint('[FCM]   Sound: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM]   WARNING: Notification permission DENIED!');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        debugPrint('[FCM]   OK: Notification permission GRANTED');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('[FCM]   Notification permission PROVISIONAL (iOS)');
      }

      // Step 2: For non-web platforms, check APNs token (iOS only).
      if (!kIsWeb) {
        try {
          debugPrint('[FCM] Step 2: Checking APNs token (iOS)...');
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) {
            final preview = apnsToken.substring(
              0,
              apnsToken.length > 20 ? 20 : apnsToken.length,
            );
            debugPrint('[FCM]   APNs token: PRESENT ($preview...)');
          } else {
            debugPrint('[FCM]   APNs token: NULL');
          }
        } catch (e) {
          debugPrint('[FCM]   APNs check skipped (not iOS): $e');
        }
      }

      // Step 3: Get and cache the FCM token.
      debugPrint('[FCM] Step 3: Getting FCM token...');
      debugPrint('[FCM]   Platform: ${kIsWeb ? "web" : "mobile"}');
      _currentToken = await _messaging.getToken(vapidKey: _webVapidKey);

      if (_currentToken != null && _currentToken!.isNotEmpty) {
        debugPrint('[FCM]   Token obtained SUCCESSFULLY');
        debugPrint('[FCM]   Token length: ${_currentToken!.length}');
        debugPrint('[FCM]   ==========================================');
        debugPrint('[FCM]   TOKEN (copy ini untuk testing):');
        debugPrint('[FCM]   $_currentToken');
        debugPrint('[FCM]   ==========================================');
      } else {
        debugPrint('[FCM]   ERROR: Token is NULL or EMPTY!');
        debugPrint('[FCM]   Penyebab kemungkinan:');
        debugPrint('[FCM]     1. Permission belum di-grant');
        debugPrint(
          '[FCM]     2. Google Play Services tidak tersedia (emulator)',
        );
        debugPrint('[FCM]     3. Firebase project tidak terkonfigurasi');
      }
    } catch (e, stack) {
      debugPrint('[FCM]   FCM INITIALIZATION FAILED!');
      debugPrint('[FCM]   Error: $e');
      debugPrint('[FCM]   Stack: $stack');
    }

    // Step 4: Listen for token refreshes.
    debugPrint('[FCM] Step 4: Setting up token refresh listener...');
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      final preview = token.substring(0, token.length > 30 ? 30 : token.length);
      debugPrint('[FCM]   Token refreshed: $preview...');
    }, onError: (e) => debugPrint('[FCM]   Token refresh error: $e'));

    // Step 5: Listen for foreground messages.
    debugPrint('[FCM] Step 5: Setting up foreground message listener...');
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (e) => debugPrint('[FCM]   Foreground message error: $e'),
    );
    debugPrint('[FCM]   onMessage listener registered');

    // Step 6: Enable foreground notification display on iOS.
    if (!kIsWeb) {
      debugPrint(
        '[FCM] Step 6: Setting foreground notification options (iOS)...',
      );
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM]   iOS foreground display enabled');
    }

    // Step 7: Handle notification tap when app was terminated.
    debugPrint(
      '[FCM] Step 7: Checking for initial message (app killed -> tap)...',
    );
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM]   App opened from KILLED state via notification');
      debugPrint('[FCM]   Title: ${initialMessage.notification?.title}');
      debugPrint('[FCM]   Body: ${initialMessage.notification?.body}');
      _onNotificationTap?.call(initialMessage);
    } else {
      debugPrint(
        '[FCM]   No initial message (app not opened via notification)',
      );
    }

    // Step 8: Handle notification tap when app was in background.
    debugPrint('[FCM] Step 8: Setting up background tap listener...');
    _backgroundTapSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('[FCM]   App opened from BACKGROUND via notification');
      debugPrint('[FCM]   Title: ${message.notification?.title}');
      debugPrint('[FCM]   Body: ${message.notification?.body}');
      _onNotificationTap?.call(message);
    }, onError: (e) => debugPrint('[FCM]   Background tap error: $e'));
    debugPrint('[FCM]   onMessageOpenedApp listener registered');

    debugPrint('[FCM] ============================================');
    debugPrint('[FCM] FcmService.initialize() COMPLETE');
    debugPrint('[FCM] ============================================');
  }

  /// Request notification permissions from the user.
  Future<NotificationSettings> requestPermission() async {
    debugPrint('[FCM] Requesting notification permission...');
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('[FCM]   Authorization: ${settings.authorizationStatus}');
    debugPrint('[FCM]   Alert: ${settings.alert}');
    debugPrint('[FCM]   Badge: ${settings.badge}');
    debugPrint('[FCM]   Sound: ${settings.sound}');
    return settings;
  }

  /// Re-fetch the FCM token after notification permission is granted.
  ///
  /// Called from the onboarding permission slide after the user taps "Izinkan".
  /// The token may have been null during initialize() if permission was not
  /// yet granted.
  Future<void> refreshToken() async {
    debugPrint('[FCM] Refreshing FCM token after permission grant...');
    try {
      _currentToken = await _messaging.getToken(vapidKey: _webVapidKey);
      if (_currentToken != null && _currentToken!.isNotEmpty) {
        debugPrint('[FCM]   Token refreshed successfully');
        debugPrint('[FCM]   Token: $_currentToken');
      } else {
        debugPrint('[FCM]   Token refresh returned NULL/EMPTY');
      }
    } catch (e) {
      debugPrint('[FCM]   Token refresh FAILED: $e');
    }
  }

  /// Handle messages received while the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] --------------------------------------------');
    debugPrint('[FCM] FOREGROUND MESSAGE RECEIVED!');
    debugPrint('[FCM]   Message ID: ${message.messageId}');
    debugPrint('[FCM]   Sent Time: ${message.sentTime}');
    if (message.notification != null) {
      debugPrint('[FCM]   Title: ${message.notification!.title}');
      debugPrint('[FCM]   Body: ${message.notification!.body}');
      debugPrint(
        '[FCM]   Image: ${message.notification!.android?.imageUrl ?? "none"}',
      );
    } else {
      debugPrint('[FCM]   DATA-ONLY message (no notification payload)');
    }
    debugPrint('[FCM]   Data: ${message.data}');
    debugPrint('[FCM] --------------------------------------------');
    _messageController.add(message);
  }

  /// Release all stream subscriptions and the message controller.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _backgroundTapSubscription?.cancel();
    _messageController.close();
  }
}
