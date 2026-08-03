import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
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
  Future<AuthEntity> call({required String npm}) {
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
      build: () => AuthBloc(FakeGetAuth(authEntity), AuthStatusNotifier()),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), AuthAuthenticated(authEntity)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is empty',
      build: () => AuthBloc(FakeGetAuth(authEntity), AuthStatusNotifier()),
      act: (bloc) => bloc.add(AuthSubmitted()),
      expect: () => [const AuthError('NPM wajib diisi')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is 10 digits (valid edge)',
      build: () => AuthBloc(FakeGetAuth(authEntity), AuthStatusNotifier()),
      act: (bloc) {
        bloc.add(AuthNpmChanged('1234567890'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), AuthAuthenticated(authEntity)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is not 10-11 digits',
      build: () => AuthBloc(FakeGetAuth(authEntity), AuthStatusNotifier()),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 10-11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM has non-numeric characters',
      build: () => AuthBloc(FakeGetAuth(authEntity), AuthStatusNotifier()),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123456789a'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 10-11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when login throws',
      build: () => AuthBloc(
        FakeGetAuth(authEntity, Exception('Invalid NPM')),
        AuthStatusNotifier(),
      ),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), const AuthError('NPM tidak terdaftar')],
    );
  });
}
