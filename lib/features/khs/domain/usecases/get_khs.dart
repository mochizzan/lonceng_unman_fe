import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/features/khs/domain/repositories/khs_repository.dart';

/// KHS use case.
class GetKhs {
  final KhsRepository repository;

  const GetKhs(this.repository);

  /// Get available semesters.
  Future<List<KhsSemesterEntity>> getSemesters({
    required String npm,
    required String password,
  }) {
    return repository.getSemesters(npm: npm, password: password);
  }

  /// Download KHS PDF for a specific semester.
  Future<void> download({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) {
    return repository.downloadKhs(
      npm: npm,
      password: password,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
  }

  /// Extract KHS data from downloaded PDF.
  Future<void> extract({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) {
    return repository.extractKhs(
      npm: npm,
      password: password,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
  }

  /// Get KHS data for a specific semester.
  Future<KhsEntity> call({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) {
    return repository.getKhsData(
      npm: npm,
      tahunAjaran: tahunAjaran,
      semester: semester,
    );
  }
}
