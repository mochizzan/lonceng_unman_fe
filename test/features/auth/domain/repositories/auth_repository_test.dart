import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  final AuthEntity result;
  FakeAuthRepository(this.result);
  @override
  Future<AuthEntity> login({required String npm}) async {
    return result;
  }
}

void main() {
  group('AuthRepository', () {
    test('interface can be implemented and called', () async {
      final now = DateTime(2025, 1, 1);
      final expected = AuthEntity(
        npm: '21081010001',
        token: 'tok',
        expiresAt: now,
      );
      final repo = FakeAuthRepository(expected);
      final result = await repo.login(npm: '21081010001');
      expect(result, expected);
    });
  });
}
