import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthEntity> login({required String npm, required String password});
}
