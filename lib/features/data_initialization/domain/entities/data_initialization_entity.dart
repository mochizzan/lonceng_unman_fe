/// Result of a single pipeline step.
enum DataInitStepResult { success, empty, error }

/// Wraps a single pipeline step outcome with its result and optional message.
class DataInitStepOutcome {
  final String step;
  final DataInitStepResult result;
  final String? message;

  const DataInitStepOutcome({
    required this.step,
    required this.result,
    this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitStepOutcome &&
          runtimeType == other.runtimeType &&
          step == other.step &&
          result == other.result &&
          message == other.message;

  @override
  int get hashCode => Object.hash(step, result, message);
}

/// Data initialization entity — tracks the post-login pipeline status.
enum DataInitStatus {
  idle,
  authenticating,
  clearingCache,
  scrapingProfile,
  gettingProfile,
  fetchingPhoto,
  downloadingKrs,
  extractingKrs,
  fetchingKrsData,
  fetchingKhsSemesters,
  downloadingKhs,
  extractingKhs,
  fetchingKhsData,
  krsEmpty,
  khsEmpty,
  photoEmpty,
  completed,
  completedWithErrors,
  failed,
}

/// Wraps [DataInitStatus] with an optional human-readable detail string
/// (e.g. tahun ajaran info during KHS download).
class DataInitProgress {
  final DataInitStatus status;
  final String? detail;

  const DataInitProgress(this.status, {this.detail});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitProgress &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          detail == other.detail;

  @override
  int get hashCode => Object.hash(status, detail);
}
