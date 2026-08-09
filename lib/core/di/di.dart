// lib/core/di/di.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
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
    debugPrint('[DI] performFullLogout() START');

    // 1. Clear all academic cache (credentials, KRS, KHS, KHS list)
    debugPrint('[DI]   Step 1: Clearing all academic cache...');
    try {
      final cache = get<AcademicCacheService>();
      await cache.clearAll();
      debugPrint('[DI]   Step 1: Cache cleared OK');
    } catch (e) {
      debugPrint('[DI]   Step 1: Cache clear FAILED: $e');
    }

    // 1b. Clear bio cache
    debugPrint('[DI]   Step 1b: Clearing bio cache...');
    try {
      final bioCache = get<BioCacheService>();
      await bioCache.clearAll();
      debugPrint('[DI]   Step 1b: Bio cache cleared OK');
    } catch (e) {
      debugPrint('[DI]   Step 1b: Bio cache clear FAILED: $e');
    }

    // 2. Cancel all scheduled notifications
    debugPrint('[DI]   Step 2: Cancelling all notifications...');
    try {
      final notifService = get<NotificationService>();
      await notifService.cancelAll();
      debugPrint('[DI]   Step 2: Notifications cancelled OK');
    } catch (e) {
      debugPrint('[DI]   Step 2: Cancel notifications FAILED: $e');
    }

    // 2b. Delete FCM token so the device is unregistered from FCM
    debugPrint('[DI]   Step 2b: Deleting FCM token...');
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.deleteToken();
      debugPrint('[DI]   Step 2b: FCM token deleted OK');
    } catch (e) {
      debugPrint('[DI]   Step 2b: Delete FCM token FAILED: $e');
    }

    // 2c. Lepas keterikatan avatar dari akun yang baru saja logout.
    // Hanya melepas NPM di cubit — box `avatar` SENGAJA tidak disentuh agar
    // foto akun lama tetap tersimpan bila akun itu login kembali.
    debugPrint('[DI]   Step 2c: Resetting avatar cubit...');
    try {
      final avatarCubit = get<AvatarCubit>();
      avatarCubit.reset();
      debugPrint('[DI]   Step 2c: Avatar reset OK');
    } catch (e) {
      debugPrint('[DI]   Step 2c: Avatar reset FAILED: $e');
    }

    // 3. Set auth status to unauthenticated
    debugPrint('[DI]   Step 3: Setting auth status to unauthenticated...');
    try {
      final authNotifier = get<AuthStatusNotifier>();
      authNotifier.setStatus(AuthStatus.unauthenticated);
      debugPrint('[DI]   Step 3: Auth status set OK');
    } catch (e) {
      debugPrint('[DI]   Step 3: Set auth status FAILED: $e');
    }

    debugPrint('[DI] performFullLogout() END');
  }
}
