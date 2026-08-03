// lib/core/auth/auth_status.dart
import 'dart:async';

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
/// concrete auth BLoC/data layer. Provides a mutable implementation
/// that can be updated when auth state changes.
abstract class AuthStatusProvider {
  /// AuthStatusProvider is an abstract interface — do not instantiate
  /// directly. Use a concrete subtype such as [AuthStatusNotifier].
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

/// Mutable [AuthStatusProvider] that emits status changes.
///
/// Injected into both the router (via [AppRouter.create]) and the
/// [AuthBloc] so that successful login updates the auth guard and
/// unblocks navigation to the home shell.
class AuthStatusNotifier implements AuthStatusProvider {
  AuthStatusNotifier([this._status = AuthStatus.unauthenticated]);

  AuthStatus _status;

  @override
  AuthStatus get currentStatus => _status;

  final StreamController<AuthStatus> _controller =
      StreamController<AuthStatus>.broadcast();

  @override
  Stream<AuthStatus> get status => _controller.stream;

  /// Update the current auth status and notify listeners.
  void setStatus(AuthStatus status) {
    if (status == _status) return;
    _status = status;
    _controller.add(status);
  }

  /// Close the backing stream controller.
  void dispose() => _controller.close();
}
