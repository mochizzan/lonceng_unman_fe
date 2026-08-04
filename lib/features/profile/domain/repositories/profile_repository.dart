// profile - Repository interface
//
// Defines the contract for retrieving profile screen data.
// Clean Architecture: presentation/domain depend on this interface,
// not on concrete data sources.

import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Fetches the aggregated profile data for the authenticated user.
  Future<ProfileEntity> getProfile();
}
