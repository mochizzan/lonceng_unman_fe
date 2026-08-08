/// Abstract interface for onboarding state persistence.
///
/// Domain layer defines the contract; data layer implements it.
abstract class OnboardingRepository {
  /// Whether the user has completed onboarding.
  bool get isCompleted;

  /// Mark onboarding as completed.
  Future<void> markCompleted();
}
