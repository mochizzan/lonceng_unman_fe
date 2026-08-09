// lib/core/constants/app_durations.dart
/// Centralized animation, transition, and network durations.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 1200);
  static const Duration countdown = Duration(milliseconds: 2000);

  // ── Network ──

  /// Max wall-clock time for a single backend request.
  ///
  /// LMS-backed endpoints proxy to an upstream campus server and are slow:
  /// `POST /api/v1/lms/login` alone has been measured at ~29.7s. The previous
  /// 30s budget left <1% headroom, so requests were aborted client-side even
  /// though the backend answered 200.
  static const Duration apiRequest = Duration(seconds: 90);

  /// Max wall-clock time for the whole post-login data pipeline.
  ///
  /// The pipeline issues 8+ sequential requests (KRS download/extract/data,
  /// then KHS semesters/download/extract/data per semester), so this cap MUST
  /// stay well above [apiRequest] or it aborts the run before the second step.
  static const Duration dataInitPipeline = Duration(minutes: 10);
}
