// profile - Repository implementation
//
// Concrete repository that delegates to [ProfileRemoteDataSource].
// Follows the same pattern as jadwal's [JadwalRepositoryImpl].

import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';
import 'package:lonceng_unman_fe/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  const ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProfileEntity> getProfile() {
    return remoteDataSource.getProfile();
  }
}
