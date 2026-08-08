/// Data initialization entity — tracks the post-login pipeline status.
enum DataInitStatus {
  idle,
  authenticating,
  clearingCache,
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

class DataInitState {
  final DataInitStatus status;
  final String? errorMessage;
  final String? failedStep;

  const DataInitState({
    required this.status,
    this.errorMessage,
    this.failedStep,
  });

  const DataInitState.idle()
    : status = DataInitStatus.idle,
      errorMessage = null,
      failedStep = null;

  const DataInitState.completed()
    : status = DataInitStatus.completed,
      errorMessage = null,
      failedStep = null;

  DataInitState.failed(String message, String step)
    : status = DataInitStatus.failed,
      errorMessage = message,
      failedStep = step;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          failedStep == other.failedStep;

  @override
  int get hashCode => Object.hash(status, errorMessage, failedStep);
}
