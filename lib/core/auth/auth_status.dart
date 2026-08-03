// lib/core/auth/auth_status.dart

/// Auth state for the router's auth guard.
enum AuthStatus {
  /// Auth state is being resolved (e.g. checking token on app start).
  unknown,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

/// Abstraction the router depends on. Decouples the router from the
/// concrete auth BLoC/data layer. Provides a stub now; swap in a real
/// implementation when auth is implemented.
abstract class AuthStatusProvider {
  /// AuthStatusProvider is an abstract interface — do not instantiate
  /// directly. Use a concrete subtype such as [StubAuthStatusProvider].
  //
  // Throwing [TypeError] (rather than being a compile-time abstract error)
  // keeps this type instantiable at the language level (so it can serve as
  // a pure interface for `implements`) while failing loudly at runtime if
  // someone attempts direct construction.
  factory AuthStatusProvider() => throw TypeError();

  /// Current auth status — read synchronously at redirect time.
  AuthStatus get currentStatus;

  /// Stream that emits when auth status changes.
  /// Drives GoRouterRefreshStream to re-evaluate GoRouter.redirect.
  Stream<AuthStatus> get status;
}

/// Stub implementation — always authenticated.
/// Replace when real auth is ready.
class StubAuthStatusProvider implements AuthStatusProvider {
  @override
  AuthStatus get currentStatus => AuthStatus.authenticated;

  @override
  Stream<AuthStatus> get status => const Stream.empty();
}
