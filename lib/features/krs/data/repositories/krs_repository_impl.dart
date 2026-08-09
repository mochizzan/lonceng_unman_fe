import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';
import 'package:lonceng_unman_fe/features/krs/domain/repositories/krs_repository.dart';

/// KRS repository implementation — delegates to KrsRemoteDataSource.
class KrsRepositoryImpl implements KrsRepository {
  final KrsRemoteDataSource remoteDataSource;
  const KrsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> downloadKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) {
    return remoteDataSource.downloadKrs(
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<void> extractKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) {
    return remoteDataSource.extractKrs(
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<KrsEntity> getKrsData({
    required String npm,
    bool forceRefresh = false,
  }) {
    return remoteDataSource.getKrsData(npm: npm, forceRefresh: forceRefresh);
  }
}
