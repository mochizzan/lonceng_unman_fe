// home - Repository implementation
//
// Concrete repository that delegates to [HomeRemoteDataSource].
// Follows the same pattern as auth's [AuthRepositoryImpl].

import 'dart:developer' as developer;

import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/home/data/datasources/home_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  const HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<HomeEntity> getHomeData() async {
    try {
      return await remoteDataSource.getHomeData();
    } on AppException {
      rethrow;
    } catch (e, st) {
      developer.log(
        'HomeRepo non-AppException: ${e.runtimeType}: $e',
        name: 'HomeRepo',
        error: e,
        stackTrace: st,
      );
      throw ServerException(
        'Gagal memuat data beranda: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
