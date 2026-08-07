import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';

/// Auth — Usecase
class GetAuth {
  final AuthRepository repository;

  const GetAuth(this.repository);

  Future<AuthEntity> call({required String npm, required String password}) {
    return repository.login(npm: npm, password: password);
  }
}
