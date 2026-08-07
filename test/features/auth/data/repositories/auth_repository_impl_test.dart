import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/models/auth_model.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

class FakeRemoteDataSource implements AuthRemoteDataSource {
  final AuthModel result;
  bool wasCalled = false;
  String? receivedNpm;
  String? receivedPassword;
  FakeRemoteDataSource(this.result);
  @override
  Future<AuthModel> login({
    required String npm,
    required String password,
  }) async {
    wasCalled = true;
    receivedNpm = npm;
    receivedPassword = password;
    return result;
  }
}

void main() {
  group('AuthRepositoryImpl', () {
    test('login delegates to remote data source', () async {
      final model = AuthModel(npm: '21081010001', password: 'testpass');
      final remote = FakeRemoteDataSource(model);
      final repository = AuthRepositoryImpl(remoteDataSource: remote);
      final result = await repository.login(
        npm: '21081010001',
        password: 'testpass',
      );
      expect(result.npm, '21081010001');
      expect(result.password, 'testpass');
      expect(remote.wasCalled, isTrue);
      expect(remote.receivedNpm, '21081010001');
      expect(remote.receivedPassword, 'testpass');
    });

    test('login returns AuthEntity (AuthModel is an AuthEntity)', () async {
      final remote = FakeRemoteDataSource(
        AuthModel(npm: '21081010002', password: 'pass2'),
      );
      final repository = AuthRepositoryImpl(remoteDataSource: remote);
      final result = await repository.login(
        npm: '21081010002',
        password: 'pass2',
      );
      expect(result, isA<AuthEntity>());
    });
  });
}
