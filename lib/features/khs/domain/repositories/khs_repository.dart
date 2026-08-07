import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';

abstract class KhsRepository {
  /// Get available semesters for a student.
  Future<List<KhsSemesterEntity>> getSemesters({
    required String npm,
    required String password,
  });

  /// Download KHS PDF for a specific semester.
  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  });

  /// Extract KHS data from downloaded PDF.
  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  });

  /// Get cached KHS data for a specific semester.
  Future<KhsEntity> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
  });
}
