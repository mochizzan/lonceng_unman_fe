// home - Repository interface
//
// Defines the contract for retrieving home screen data.
// Clean Architecture: presentation/domain depend on this interface,
// not on concrete data sources.

import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';

abstract class HomeRepository {
  /// Fetches the complete home screen data for the authenticated user.
  Future<HomeEntity> getHomeData();
}
