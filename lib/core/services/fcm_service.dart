// lib/core/services/fcm_service.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;

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

    try {
      // Step 1: For non-web platforms, ensure APNs token is available before FCM API calls.
      if (!kIsWeb) {
        try {
          developer.log('Step 1: Checking APNs token (iOS)...', name: 'FCM');
          final apnsToken = await _messaging.getAPNSToken();
          developer.log('APNs token: $apnsToken', name: 'FCM');
        } catch (e) {
          developer.log('APNs token check skipped: $e', name: 'FCM');
        }
      }

      // Step 2: Get and cache the FCM token.
      // Token may be null if notification permission is not yet granted;
      // it will be fetched again after the user grants permission in onboarding.
      developer.log('Step 2: Getting FCM token...', name: 'FCM');
      _currentToken = await _messaging.getToken(vapidKey: _webVapidKey);
      developer.log('Token: $_currentToken', name: 'FCM');
    } catch (e, stack) {
      developer.log('FAILED: $e', name: 'FCM', error: e);
      developer.log('Stack: $stack', name: 'FCM');
    }

    // Listen for token refreshes.
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      developer.log('Token refreshed: $token', name: 'FCM');
    }, onError: (e) => developer.log('Token refresh error: $e', name: 'FCM'));

    // Listen for foreground messages.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (e) =>
          developer.log('Foreground message error: $e', name: 'FCM'),
    );

    // Enable foreground notification display on iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle notification tap when app was terminated.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        'App opened from terminated state via notification',
        name: 'FCM',
      );
      _onNotificationTap?.call(initialMessage);
    }

    // Handle notification tap when app was in background.
    _backgroundTapSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      developer.log('App opened from background via notification', name: 'FCM');
      _onNotificationTap?.call(message);
    }, onError: (e) => developer.log('Background tap error: $e', name: 'FCM'));
  }

  /// Request notification permissions from the user.
  Future<NotificationSettings> requestPermission() async {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  /// Re-fetch the FCM token after notification permission is granted.
  ///
  /// Called from the onboarding permission slide after the user taps "Izinkan".
  /// The token may have been null during initialize() if permission was not
  /// yet granted.
  Future<void> refreshToken() async {
    try {
      _currentToken = await _messaging.getToken(vapidKey: _webVapidKey);
      developer.log(
        'Token refreshed after permission grant: $_currentToken',
        name: 'FCM',
      );
    } catch (e) {
      developer.log(
        'Token refresh after permission failed: $e',
        name: 'FCM',
        error: e,
      );
    }
  }

  /// Handle messages received while the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('Foreground message: ${message.messageId}', name: 'FCM');
    if (message.notification != null) {
      developer.log('Title: ${message.notification!.title}', name: 'FCM');
      developer.log('Body: ${message.notification!.body}', name: 'FCM');
    }
    developer.log('Data: ${message.data}', name: 'FCM');
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
