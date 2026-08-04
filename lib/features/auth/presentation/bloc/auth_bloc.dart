// auth - BLoC
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetAuth _getAuth;
  final AuthStatusNotifier _authStatusNotifier;

  AuthBloc(this._getAuth, this._authStatusNotifier)
    : super(const AuthInitial()) {
    on<AuthNpmChanged>(_onNpmChanged);
    on<AuthSubmitted>(_onSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  String _npm = '';

  String get npm => _npm;

  void _onNpmChanged(AuthNpmChanged event, Emitter emit) {
    _npm = event.npm;
  }

  Future<void> _onSubmitted(AuthSubmitted event, Emitter emit) async {
    if (_npm.isEmpty) {
      emit(const AuthError('NPM wajib diisi'));
      return;
    }
    if (!RegExp(r'^\d{10,11}$').hasMatch(_npm)) {
      emit(const AuthError('NPM harus 10-11 digit angka'));
      return;
    }
    emit(AuthLoading());
    try {
      final AuthEntity user = await _getAuth(npm: _npm);
      _authStatusNotifier.setStatus(AuthStatus.authenticated);
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } on NetworkException catch (e) {
      emit(AuthError(e.message));
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Gagal terhubung ke server'));
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter emit) {
    _npm = '';
    _authStatusNotifier.setStatus(AuthStatus.unauthenticated);
    emit(const AuthInitial());
  }
}
