// auth - BLoC
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetAuth _getAuth;
  final SaveAuthCredentials _saveCredentials;
  final LoadAuthCredentials _loadCredentials;

  AuthBloc(
    this._getAuth, {
    SaveAuthCredentials? saveCredentials,
    LoadAuthCredentials? loadCredentials,
  }) : _saveCredentials =
           saveCredentials ?? Services.get<SaveAuthCredentials>(),
       _loadCredentials =
           loadCredentials ?? Services.get<LoadAuthCredentials>(),
       super(const AuthInitial()) {
    on<AuthNpmChanged>(_onNpmChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthSubmitted>(_onSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  String _npm = '';
  String _password = '';

  String get npm => _npm;
  String get password => _password;

  void _onNpmChanged(AuthNpmChanged event, Emitter emit) {
    _npm = event.npm;
  }

  void _onPasswordChanged(AuthPasswordChanged event, Emitter emit) {
    _password = event.password;
  }

  /// Check for cached credentials and auto-login if found.
  /// Returns true if cached credentials were loaded (caller should skip login).
  Future<bool> checkCachedCredentials() async {
    final cached = await _loadCredentials();
    if (cached == null) return false;

    _npm = cached['npm']!;
    _password = cached['password']!;
    return true;
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
    if (_password.isEmpty) {
      emit(const AuthError('Password wajib diisi'));
      return;
    }
    emit(AuthLoading());
    try {
      final AuthEntity user = await _getAuth(npm: _npm, password: _password);
      // Cache credentials for next launch — await to prevent race condition
      // with DataInitializationPage reading the same cache file.
      await _saveCredentials(npm: _npm, password: _password);
      // NOTE: AuthStatusNotifier.setStatus(AuthStatus.authenticated) is NOT
      // called here. The login page calls it after the data-init pipeline
      // completes, so the router redirect to /home only fires once data is
      // ready. This prevents the router from destroying the progress UI.
      emit(AuthAuthenticated(user));
    } on AppException catch (e) {
      emit(AuthError(e.message, error: e));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter emit,
  ) async {
    _npm = '';
    _password = '';
    await Services.performFullLogout();
    emit(const AuthInitial());
  }
}
