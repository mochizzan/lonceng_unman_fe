// Theme state management for light/dark/system switching.
// Follows the same pattern as AuthStatusNotifier.
import 'dart:async';

import 'package:flutter/material.dart';

/// Theme mode options for the application.
enum AppThemeMode {
  /// Follow system theme.
  system,

  /// Always use light theme.
  light,

  /// Always use dark theme.
  dark,
}

/// Provides the current [AppThemeMode] and emits changes.
///
/// Injected into [MaterialApp.router] via [themeMode] and consumed by
/// the settings page to switch themes at runtime.
class ThemeNotifier {
  ThemeNotifier([this._mode = AppThemeMode.system]);

  AppThemeMode _mode;

  /// Current theme mode.
  AppThemeMode get currentMode => _mode;

  /// Converts [AppThemeMode] to Flutter's [ThemeMode].
  ThemeMode get themeMode => switch (_mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  final StreamController<AppThemeMode> _controller =
      StreamController<AppThemeMode>.broadcast();

  /// Stream that emits when theme mode changes.
  Stream<AppThemeMode> get mode => _controller.stream;

  /// Update the current theme mode and notify listeners.
  void setMode(AppThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _controller.add(mode);
  }

  /// Close the backing stream controller.
  void dispose() => _controller.close();
}
