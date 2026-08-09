// auth - BLoC
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetAuth _getAuth;
  final SaveAuthCredentials _saveCredentials;
  final LoadAuthCredentials _loadCredentials;
  final StudentProfileRemoteDataSource _profileDataSource;
  final StudentProfileCacheService _profileCacheService;

  AuthBloc(
    this._getAuth, {
    SaveAuthCredentials? saveCredentials,
    LoadAuthCredentials? loadCredentials,
    StudentProfileRemoteDataSource? profileDataSource,
    StudentProfileCacheService? profileCacheService,
  }) : _saveCredentials =
           saveCredentials ?? Services.get<SaveAuthCredentials>(),
       _loadCredentials =
           loadCredentials ?? Services.get<LoadAuthCredentials>(),
       _profileDataSource =
           profileDataSource ?? Services.get<StudentProfileRemoteDataSource>(),
       _profileCacheService =
           profileCacheService ?? Services.get<StudentProfileCacheService>(),
       super(const AuthInitial()) {
    on<AuthNpmChanged>(_onNpmChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthSubmitted>(_onSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileScraped>(_onProfileScraped);
    on<AuthProfileConfirmed>(_onProfileConfirmed);
    on<AuthProfileRejected>(_onProfileRejected);
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

      // Scrape student profile for confirmation flow.
      try {
        await _profileDataSource.scrapeProfile(npm: _npm, password: _password);
        final profileModel = await _profileDataSource.getProfile(
          npm: _npm,
          password: _password,
        );
        emit(AuthProfileReview(profileModel, _npm, _password));
      } catch (e) {
        // Profile scrape failed — fall back to old flow for backward
        // compatibility (e.g. backend not ready, network error).
        debugPrint('[AUTH] Profile scrape failed, falling back: $e');
        emit(AuthAuthenticated(user));
      }
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
    debugPrint('[AUTH] _onLogoutRequested() START');
    debugPrint('[AUTH]   Clearing credentials...');
    _npm = '';
    _password = '';
    debugPrint('[AUTH]   Credentials cleared OK');
    debugPrint('[AUTH]   Calling performFullLogout...');
    await Services.performFullLogout();
    debugPrint('[AUTH]   performFullLogout OK');
    emit(const AuthInitial());
    debugPrint('[AUTH] _onLogoutRequested() END');
  }

  Future<void> _onProfileScraped(AuthProfileScraped event, Emitter emit) async {
    emit(AuthProfileReview(event.profile, event.npm, event.password));
  }

  Future<void> _onProfileConfirmed(
    AuthProfileConfirmed event,
    Emitter emit,
  ) async {
    // Profile is already cached by StudentProfileRemoteDataSourceImpl during
    // the scrape + getProfile flow in _onSubmitted. No additional cache write
    // needed — just build the AuthEntity and transition to authenticated.
    final user = AuthEntity(npm: _npm, password: _password);
    emit(AuthAuthenticated(user));
  }

  Future<void> _onProfileRejected(
    AuthProfileRejected event,
    Emitter emit,
  ) async {
    // Save NPM before clearing for cache cleanup
    final npmToClear = _npm;
    _npm = '';
    _password = '';
    // Clear the cached profile data for this NPM on rejection.
    if (npmToClear.isNotEmpty) {
      try {
        await _profileCacheService.clearProfile(npm: npmToClear);
      } catch (_) {
        // Non-fatal: cache might not exist yet.
      }
    }
    emit(const AuthInitial());
  }
}
