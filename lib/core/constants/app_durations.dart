// lib/core/constants/app_durations.dart
/// Centralized animation and transition durations.
abstract final class AppDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 1200);
  static const Duration countdown = Duration(milliseconds: 2000);

  // ─── Shimmer / Loading ────────────────────────────────
  static const Duration shimmer = Duration(milliseconds: 1500);
}
