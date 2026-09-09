import 'dart:typed_data';

import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';

class DataInitializationRepositoryImpl implements DataInitializationRepository {
  final DataInitializationRemoteDataSource remoteDataSource;

  const DataInitializationRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) {
    return remoteDataSource.initialize(
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
      isPullRefresh: isPullRefresh,
    );
  }

  @override
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  }) {
    return remoteDataSource.resumeFrom(
      failedStep: failedStep,
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
      cachedPhotoBytes: cachedPhotoBytes,
    );
  }
}
