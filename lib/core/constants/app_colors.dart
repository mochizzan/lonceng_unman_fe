// lib/core/constants/app_colors.dart
/// Centralized color constants for shadows, opacities, and non-theme colors.
///
/// Theme colors live in lib/core/theme/theme.dart (ColorScheme + AppColors).
/// This file holds values that are NOT part of the Material 3 theme system.
abstract final class ColorValues {
  // ─── Common Opacities (for withValues(alpha:)) ────────
  static const double opacityLow = 0.08;
  static const double opacityMedium = 0.12;
  static const double opacityHigh = 0.5;
  static const double opacityVeryHigh = 0.6;
  static const double opacityMax = 0.7;
  static const double opacityFull = 0.8;
  static const double opacityNearFull = 0.85;

  // ─── Shadow Opacities ──────────────────────────────────
  static const double shadowLow = 0.06;
}
