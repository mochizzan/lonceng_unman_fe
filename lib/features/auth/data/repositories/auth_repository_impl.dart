// AuthRepository implementation — delegates login to AuthRemoteDataSource.
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  const AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthEntity> login({
    required String npm,
    required String password,
  }) async {
    return remoteDataSource.login(npm: npm, password: password);
  }
}
