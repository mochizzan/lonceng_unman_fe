import 'package:hive_ce/hive.dart';

/// Local data source for onboarding state persistence.
///
/// Uses a dedicated Hive box (`onboarding_box`) to track whether the user
/// has completed the onboarding flow. This is separate from academic cache
/// boxes to keep concerns isolated.
class OnboardingLocalDataSource {
  static const String boxName = 'onboarding_box';
  static const String _completedKey = 'onboarding_completed';

  late Box<bool> _box;

  /// Open the onboarding Hive box. Must be called once at app startup.
  Future<void> init() async {
    _box = await Hive.openBox<bool>(boxName);
  }

  /// Whether the user has completed onboarding.
  bool get isCompleted => _box.get(_completedKey) ?? false;

  /// Mark onboarding as completed.
  Future<void> markCompleted() async {
    await _box.put(_completedKey, true);
  }
}
