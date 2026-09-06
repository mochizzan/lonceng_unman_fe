import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// View-owned wakelock wrapper bound to [DataInitBloc.isRunning].
///
/// Guard [_held] prevents double enable/disable from two listeners.
/// Not a singleton — instance owned by the [State] that listens to the bloc.
/// Catches [PlatformException]/web-stub failures so pipeline never throws.
class WakelockController {
  bool _held = false;

  bool get isHeld => _held;

  Future<void> enable() async {
    if (_held) return;
    try {
      await WakelockPlus.enable();
      _held = true;
      debugPrint('[WAKELOCK] enabled');
    } catch (e) {
      debugPrint('[WAKELOCK] enable failed: $e');
    }
  }

  Future<void> disable() async {
    if (!_held) return;
    try {
      await WakelockPlus.disable();
      _held = false;
      debugPrint('[WAKELOCK] disabled');
    } catch (e) {
      debugPrint('[WAKELOCK] disable failed: $e');
    }
  }
}
