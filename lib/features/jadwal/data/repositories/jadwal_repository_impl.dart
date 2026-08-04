// jadwal - Repository implementation
//
// Concrete repository that delegates to [JadwalRemoteDataSource].
// Follows the same pattern as home's [HomeRepositoryImpl].

import 'package:lonceng_unman_fe/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/repositories/jadwal_repository.dart';

class JadwalRepositoryImpl implements JadwalRepository {
  final JadwalRemoteDataSource remoteDataSource;

  const JadwalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<JadwalEntity> getJadwal() {
    return remoteDataSource.getJadwal();
  }
}
