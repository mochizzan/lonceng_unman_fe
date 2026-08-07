// jadwal - Repository implementation
//
// Concrete repository that delegates to [JadwalRemoteDataSource].
// Follows the same pattern as home's [HomeRepositoryImpl].

import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/repositories/jadwal_repository.dart';

class JadwalRepositoryImpl implements JadwalRepository {
  final JadwalRemoteDataSource remoteDataSource;

  const JadwalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<JadwalEntity> getJadwal() async {
    try {
      return await remoteDataSource.getJadwal();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Gagal memuat data jadwal: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
