/// Data initialization entity — tracks the post-login pipeline status.
enum DataInitStatus {
  idle,
  authenticating,
  clearingCache,
  scrapingProfile,
  gettingProfile,
  downloadingKrs,
  extractingKrs,
  fetchingKrsData,
  fetchingKhsSemesters,
  downloadingKhs,
  extractingKhs,
  fetchingKhsData,
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
