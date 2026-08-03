// home - Repository implementation
//
// Concrete repository that delegates to [HomeRemoteDataSource].
// Follows the same pattern as auth's [AuthRepositoryImpl].

import 'package:lonceng_unman_fe/features/home/data/datasources/home_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  const HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<HomeEntity> getHomeData() {
    return remoteDataSource.getHomeData();
  }
}
