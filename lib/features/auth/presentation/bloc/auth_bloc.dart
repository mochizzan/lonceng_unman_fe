// auth - BLoC
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetAuth _getAuth;
  final AuthStatusNotifier _authStatusNotifier;
  final AcademicCacheService _academicCacheService;

  AuthBloc(
    this._getAuth,
    this._authStatusNotifier, {
    AcademicCacheService? academicCacheService,
  }) : _academicCacheService =
           academicCacheService ?? Services.get<AcademicCacheService>(),
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
    final cached = await _academicCacheService.loadCredentials();
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
      await _academicCacheService.saveCredentials(
        npm: _npm,
        password: _password,
      );
      _authStatusNotifier.setStatus(AuthStatus.authenticated);
      emit(AuthAuthenticated(user));
    } on AppException catch (e) {
      emit(AuthError(e.message, error: e));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter emit) {
    _npm = '';
    _password = '';
    try {
      _academicCacheService.clearCredentials();
    } catch (e) {
      developer.log(
        'AuthBloc: failed to clear academic cache: $e',
        name: 'AuthBloc',
      );
    }
    _authStatusNotifier.setStatus(AuthStatus.unauthenticated);
    emit(const AuthInitial());
  }
}
