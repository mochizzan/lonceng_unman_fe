// Connectivity detection — wraps `connectivity_plus` plugin into a
// simple bool + Stream<bool> API. Registered as a singleton in the
// DI container so any bloc/cubit/widget can listen without rebuilding
// the underlying plugin.
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Abstract interface so tests can supply a fake without depending
/// on the `connectivity_plus` plugin.
abstract class ConnectivityService {
  /// Current connectivity status. Best-effort: defaults to `true` until
  /// the first `checkConnectivity()` result arrives (avoids a false
  /// "offline" flash on app launch).
  bool get isOnline;

  /// Broadcast stream of connectivity transitions. Only emits when the
  /// status actually changes (online→offline or vice versa) to avoid
  /// spurious rebuilds.
  Stream<bool> get onStatusChange;

  /// Re-check connectivity on demand. Used by the lifecycle observer
  /// when the app comes back to the foreground.
  Future<void> refresh();
}

/// Production implementation backed by `connectivity_plus`.
class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl(Connectivity connectivity) : _conn = connectivity {
    debugPrint('[CONNECTIVITY] initializing service');
    // Best-effort initial check (fire-and-forget; result updates _lastIsOnline).
    _conn.checkConnectivity().then(_updateFromResult);
    // Subscribe to real-time changes.
    _subscription = _conn.onConnectivityChanged.listen(
      _updateFromResult,
      onError: (Object e, StackTrace st) {
        debugPrint('[CONNECTIVITY] stream error: $e');
      },
    );
  }

  final Connectivity _conn;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  final _controller = StreamController<bool>.broadcast();
  bool _lastIsOnline = true;

  @override
  bool get isOnline => _lastIsOnline;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  @override
  Future<void> refresh() async {
    debugPrint('[CONNECTIVITY] refresh() called');
    final result = await _conn.checkConnectivity();
    _updateFromResult(result);
  }

  /// Internal: filter connectivity_plus results to a bool and emit
  /// only on transitions.
  void _updateFromResult(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _lastIsOnline) {
      debugPrint(
        '[CONNECTIVITY] transition: $_lastIsOnline → $online (raw=$results)',
      );
      _lastIsOnline = online;
      _controller.add(online);
    }
  }

  /// Free plugin resources. Call from app shutdown or in tests.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
    debugPrint('[CONNECTIVITY] service disposed');
  }
}
