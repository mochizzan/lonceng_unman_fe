import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';
import 'package:lonceng_unman_fe/features/krs/domain/repositories/krs_repository.dart';

/// KRS use case.
class GetKrs {
  final KrsRepository repository;

  const GetKrs(this.repository);

  /// Download KRS PDF from LMS.
  Future<void> download({required String npm, required String password}) {
    return repository.downloadKrs(npm: npm, password: password);
  }

  /// Extract KRS data from downloaded PDF.
  Future<void> extract({required String npm, required String password}) {
    return repository.extractKrs(npm: npm, password: password);
  }

  /// Get KRS data.
  Future<KrsEntity> call({required String npm}) {
    return repository.getKrsData(npm: npm);
  }
}
