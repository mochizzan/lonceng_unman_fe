import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';

class GetDataInitialization {
  final DataInitializationRepository repository;

  const GetDataInitialization(this.repository);

  Stream<DataInitProgress> call({
    required String npm,
    required String password,
  }) {
    return repository.initialize(npm: npm, password: password);
  }
}
