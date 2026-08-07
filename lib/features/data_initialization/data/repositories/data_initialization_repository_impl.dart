import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';

class DataInitializationRepositoryImpl implements DataInitializationRepository {
  final DataInitializationRemoteDataSource remoteDataSource;

  const DataInitializationRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<DataInitStatus> initialize({
    required String npm,
    required String password,
  }) {
    return remoteDataSource.initialize(npm: npm, password: password);
  }
}
