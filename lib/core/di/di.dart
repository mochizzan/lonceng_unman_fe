// lib/core/di/di.dart
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Simple service locator for dependency injection.
///
/// This is a lightweight alternative to get_it for small projects.
/// For larger projects, consider using get_it or riverpod.
///
/// Usage:
/// ```dart
/// // Register a service
/// Services.register<FcmService>(FcmService.instance);
///
/// // Get a service
/// final fcm = Services.get<FcmService>();
/// ```
class Services {
  Services._();

  static final Map<Type, dynamic> _services = {};

  /// Register a service instance.
  static void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a registered service instance.
  /// Throws [StateError] if not registered.
  static T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw StateError(
        'Service $T not registered. Call Services.register() first.',
      );
    }
    return service as T;
  }

  /// Clear all registered services (useful for testing).
  static void clear() {
    _services.clear();
  }

  /// Perform a full logout: clear all caches, cancel notifications,
  /// and set auth status to unauthenticated.
  ///
  /// This is the single source of truth for logout. All logout paths
  /// (user-initiated, 401 handler) must call this method.
  static Future<void> performFullLogout() async {
    // 1. Clear all academic cache (credentials, KRS, KHS, KHS list)
    final cache = get<AcademicCacheService>();
    await cache.clearAll();

    // 2. Cancel all scheduled notifications
    try {
      final notifService = get<NotificationService>();
      await notifService.cancelAll();
    } catch (_) {
      // Notification service might not be registered in DI yet
    }

    // 2b. Delete FCM token so the device is unregistered from FCM
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.deleteToken();
    } catch (_) {}

    // 3. Set auth status to unauthenticated
    final authNotifier = get<AuthStatusNotifier>();
    authNotifier.setStatus(AuthStatus.unauthenticated);
  }
}
