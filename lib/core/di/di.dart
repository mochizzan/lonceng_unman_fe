// lib/core/di/di.dart
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
}
