import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';

class FakeAuthRepository implements AuthRepository {
  final AuthEntity result;
  FakeAuthRepository(this.result);
  @override
  Future<AuthEntity> login({
    required String npm,
    required String password,
  }) async {
    return result;
  }
}

void main() {
  group('GetAuth', () {
    test('calls repository.login and returns result', () async {
      final now = DateTime(2025, 1, 1);
      final expected = AuthEntity(
        npm: '21081010001',
        token: 'tok',
        expiresAt: now,
      );
      final repo = FakeAuthRepository(expected);
      final usecase = GetAuth(repo);
      final result = await usecase(npm: '21081010001', password: 'pass123');
      expect(result, expected);
    });
  });
}
