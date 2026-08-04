// Theme state management for light/dark/system switching.
// Follows the same pattern as AuthStatusNotifier.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options for the application.
enum AppThemeMode {
  /// Always use light theme.
  light,

  /// Always use dark theme.
  dark,

  /// Follow system theme.
  system,
}

/// Provides the current [AppThemeMode] and notifies listeners of changes.
///
/// Injected into [MaterialApp.router] via [themeMode] and consumed by
/// the settings page to switch themes at runtime.
class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  AppThemeMode _mode = AppThemeMode.system;

  /// Current theme mode.
  AppThemeMode get currentMode => _mode;

  /// Converts [AppThemeMode] to Flutter's [ThemeMode].
  ThemeMode get themeMode => switch (_mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_themeKey) ?? 2; // default to system (index 2)
      _mode = AppThemeMode.values[index];
      notifyListeners();
    } catch (e) {
      // SharedPreferences not available (e.g., in tests), use default
      _mode = AppThemeMode.system;
    }
  }

  /// Update the current theme mode, persist it, and notify listeners.
  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // SharedPreferences not available (e.g., in tests), skip persistence
    }
  }
}
