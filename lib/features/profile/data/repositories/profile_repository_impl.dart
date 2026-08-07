// profile - Repository implementation
//
// Concrete repository that delegates to [ProfileRemoteDataSource].
// Follows the same pattern as jadwal's [JadwalRepositoryImpl].

import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';
import 'package:lonceng_unman_fe/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  const ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProfileEntity> getProfile() async {
    try {
      return await remoteDataSource.getProfile();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Gagal memuat data profil: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
