// lib/core/services/fcm_service.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';

/// VAPID key for web push notifications.
/// Obtain from Firebase Console → Settings → Cloud Messaging → Web Push certificates.
const String _webVapidKey =
    'BEOyeFCQemJDI3vFVnrFP5meGjaMmnEFfnt0XaZUz5ciIT46x5EmdhPqGdxHiYX7U4dB12Q76K6E1mxwgu6s0rk';

/// Top-level background message handler.
///
/// Must be a top-level function (not a class method or anonymous closure)
/// and annotated with @pragma('vm:entry-point') to prevent tree-shaking
/// in release builds.
///
/// This runs in a separate isolate — cannot update app state or UI.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Background message received: ${message.messageId}',
    name: 'FCM.Background',
  );

  if (message.notification != null) {
    developer.log(
      'Title: ${message.notification!.title}, Body: ${message.notification!.body}',
      name: 'FCM.Background',
    );
  }

  developer.log('Data: ${message.data}', name: 'FCM.Background');
}

/// Callback type for handling notification interactions.
typedef NotificationTapCallback = void Function(RemoteMessage message);

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

  /// Current FCM registration token. Cached after first retrieval.
  String? _currentToken;

  /// Stream subscription for token refresh.
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Stream subscription for foreground messages.
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  /// Stream subscription for notification taps from background.
  StreamSubscription<RemoteMessage>? _backgroundTapSubscription;

  /// Callback for handling notification taps (set by the app).
  NotificationTapCallback? _onNotificationTap;

  /// Initialize FCM: request permission, get token, set up listeners.
  ///
  /// Call this after Firebase.initializeApp() in main().
  ///
  /// [onNotificationTap] is called when user taps a notification
  /// (both from terminated and background states).
  Future<void> initialize({NotificationTapCallback? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    try {
      // Step 1: Request notification permission (required for Android 13+ and iOS).
      developer.log('Step 1: Requesting permission...', name: 'FCM');
      final settings = await _requestPermission();
      developer.log(
        'Permission status: ${settings.authorizationStatus}',
        name: 'FCM',
      );

      // Step 2: For iOS, ensure APNs token is available before FCM API calls.
      if (Platform.isIOS) {
        developer.log('Step 2: Checking APNs token (iOS)...', name: 'FCM');
        final apnsToken = await _messaging.getAPNSToken();
        developer.log('APNs token: $apnsToken', name: 'FCM');
      }

      // Step 3: Get and cache the FCM token.
      developer.log('Step 3: Getting FCM token...', name: 'FCM');
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
    });

    // Listen for foreground messages.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
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
    });
  }

  /// Request notification permissions from the user.
  Future<NotificationSettings> _requestPermission() async {
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
}
