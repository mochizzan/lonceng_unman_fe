import 'package:lonceng_unman_fe/features/khs/data/datasources/khs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/features/khs/domain/repositories/khs_repository.dart';

/// KHS repository implementation — delegates to KhsRemoteDataSource.
class KhsRepositoryImpl implements KhsRepository {
  final KhsRemoteDataSource remoteDataSource;
  const KhsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<KhsSemesterEntity>> getSemesters({
    required String npm,
    required String password,
  }) {
    return remoteDataSource.getSemesters(npm: npm, password: password);
  }

  @override
  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) {
    return remoteDataSource.downloadKhs(
      npm: npm,
      password: password,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
  }

  @override
  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) {
    return remoteDataSource.extractKhs(
      npm: npm,
      password: password,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
  }

  @override
  Future<KhsEntity> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) {
    return remoteDataSource.getKhsData(
      npm: npm,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
  }
}
