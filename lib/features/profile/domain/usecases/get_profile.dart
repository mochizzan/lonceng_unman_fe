// profile - Usecase
//
// Business-logic entry point for retrieving profile screen data.
// Follows the same pattern as jadwal's [GetJadwal] usecase.

import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';
import 'package:lonceng_unman_fe/features/profile/domain/repositories/profile_repository.dart';

/// Retrieves the profile screen data for the authenticated user.
class GetProfile {
  final ProfileRepository repository;

  const GetProfile(this.repository);

  Future<ProfileEntity> call() => repository.getProfile();

  /// Fetches KRS + KHS from remote API and updates local cache.
  Future<void> refreshFromRemote() => repository.refreshFromRemote();
}
