import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

abstract class KrsRepository {
  /// Download KRS PDF from LMS.
  Future<void> downloadKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  });

  /// Extract KRS data from downloaded PDF.
  Future<void> extractKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  });

  /// Get cached KRS data.
  Future<KrsEntity> getKrsData({
    required String npm,
    bool forceRefresh = false,
  });
}
