// auth - BLoC
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
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
  final AcademicCacheService _academicCacheService;

  AuthBloc(
    this._getAuth, {
    SaveAuthCredentials? saveCredentials,
    LoadAuthCredentials? loadCredentials,
    StudentProfileRemoteDataSource? profileDataSource,
    StudentProfileCacheService? profileCacheService,
    AcademicCacheService? academicCacheService,
  }) : _saveCredentials =
           saveCredentials ?? Services.get<SaveAuthCredentials>(),
       _loadCredentials =
           loadCredentials ?? Services.get<LoadAuthCredentials>(),
       _profileDataSource =
           profileDataSource ?? Services.get<StudentProfileRemoteDataSource>(),
       _profileCacheService =
           profileCacheService ?? Services.get<StudentProfileCacheService>(),
       _academicCacheService =
           academicCacheService ?? Services.get<AcademicCacheService>(),
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
      // Authenticate credentials — result not used; credentials are
      // cached only after user confirms profile in _onProfileConfirmed.
      await _getAuth(npm: _npm, password: _password);

      // Scrape student profile for confirmation flow.
      try {
        await _profileDataSource.scrapeProfile(npm: _npm, password: _password);
        final profileModel = await _profileDataSource.getProfilePreview(
          npm: _npm,
          password: _password,
        );
        emit(AuthProfileReview(profileModel, _npm, _password));
      } catch (e) {
        debugPrint('[AUTH] Profile fetch failed: $e');
        emit(AuthError('Gagal mengambil profil'));
        // Delay 3 seconds → return to login
        await Future.delayed(const Duration(seconds: 3));
        emit(const AuthInitial());
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
    // Save credentials HERE (after user confirms profile)
    await _saveCredentials(npm: _npm, password: _password);
    final user = AuthEntity(npm: _npm, password: _password);
    emit(AuthAuthenticated(user));
  }

  Future<void> _onProfileRejected(
    AuthProfileRejected event,
    Emitter emit,
  ) async {
    final npmToClear = _npm;
    _npm = '';
    _password = '';

    // Clear profile cache
    if (npmToClear.isNotEmpty) {
      try {
        await _profileCacheService.clearProfile(npm: npmToClear);
      } catch (_) {}
    }

    // Clear credentials cache (FIX: prevent auto-login loop)
    try {
      await _academicCacheService.clearCredentials();
    } catch (_) {}

    emit(const AuthInitial());
  }
}
