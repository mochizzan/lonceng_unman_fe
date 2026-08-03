import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
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

void main() {
  final now = DateTime(2025, 1, 1);
  final authEntity = AuthEntity(
    npm: '21081010001',
    token: 'tok',
    expiresAt: now,
  );

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on valid submit',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthPasswordChanged('pass123'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), AuthAuthenticated(authEntity)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is empty',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) => bloc.add(AuthSubmitted()),
      expect: () => [const AuthError('NPM dan password wajib diisi')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is not 11 digits',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123'));
        bloc.add(AuthPasswordChanged('pass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when login throws',
      build: () => AuthBloc(FakeGetAuth(authEntity, Exception('Invalid NPM'))),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthPasswordChanged('wrong'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM atau password salah')],
    );

    blocTest<AuthBloc, AuthState>(
      'password visibility toggles',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) => bloc.add(AuthPasswordVisibilityToggled()),
      verify: (bloc) => expect(bloc.passwordVisible, isTrue),
    );

    blocTest<AuthBloc, AuthState>(
      'remember me toggles',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) => bloc.add(AuthRememberMeToggled(true)),
      verify: (bloc) => expect(bloc.rememberMe, isTrue),
    );
  });
}
