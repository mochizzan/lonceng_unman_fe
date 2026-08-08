import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class FakeGetAuth implements GetAuth {
  final AuthEntity result;
  final Exception? error;
  FakeGetAuth(this.result, [this.error]);

  @override
  AuthRepository get repository =>
      throw UnsupportedError('repository not needed for tests');

  @override
  Future<AuthEntity> call({required String npm, required String password}) {
    if (error != null) throw error!;
    return Future.value(result);
  }
}

/// No-op save credentials for tests.
class FakeSaveAuthCredentials implements SaveAuthCredentials {
  @override
  Future<void> call({required String npm, required String password}) async {}
}

/// No-op load credentials for tests.
class FakeLoadAuthCredentials implements LoadAuthCredentials {
  @override
  Future<Map<String, String>?> call() async => null;
}

void main() {
  final authEntity = AuthEntity(npm: '21081010001', password: 'testpass');

  AuthBloc _bloc(GetAuth getAuth) => AuthBloc(
    getAuth,
    saveCredentials: FakeSaveAuthCredentials(),
    loadCredentials: FakeLoadAuthCredentials(),
  );

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on valid submit',
      build: () => _bloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), AuthAuthenticated(authEntity)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is empty',
      build: () => _bloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM wajib diisi')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when password is empty',
      build: () => _bloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('Password wajib diisi')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is 10 digits (valid edge)',
      build: () => _bloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('1234567890'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), AuthAuthenticated(authEntity)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is not 10-11 digits',
      build: () => _bloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 10-11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM has non-numeric characters',
      build: () => _bloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123456789a'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 10-11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when login throws',
      build: () =>
          _bloc(FakeGetAuth(authEntity, NetworkException('Tidak ada koneksi'))),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), const AuthError('Tidak ada koneksi')],
    );
  });
}
