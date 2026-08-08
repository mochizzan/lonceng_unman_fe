import 'package:lonceng_unman_fe/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Implementation of [OnboardingRepository] backed by Hive.
class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _dataSource;

  OnboardingRepositoryImpl(this._dataSource);

  @override
  bool get isCompleted => _dataSource.isCompleted;

  @override
  Future<void> markCompleted() => _dataSource.markCompleted();
}
