// home - Usecase
//
// Business-logic entry point for retrieving home screen data.
// Follows the same pattern as auth's [GetAuth] usecase.

import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/features/home/domain/repositories/home_repository.dart';

/// Retrieves the home screen data for the authenticated user.
class GetHome {
  final HomeRepository repository;

  const GetHome(this.repository);

  Future<HomeEntity> call() => repository.getHomeData();
}
