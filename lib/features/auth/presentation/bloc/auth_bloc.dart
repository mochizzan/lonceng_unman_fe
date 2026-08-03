// auth - BLoC
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetAuth _getAuth;

  AuthBloc(this._getAuth) : super(const AuthInitial()) {
    on<AuthNpmChanged>(_onNpmChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<AuthRememberMeToggled>(_onRememberMeToggled);
    on<AuthSubmitted>(_onSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  String _npm = '';
  String _password = '';
  bool _passwordVisible = false;
  bool _rememberMe = false;

  String get npm => _npm;
  String get password => _password;
  bool get passwordVisible => _passwordVisible;
  bool get rememberMe => _rememberMe;

  void _onNpmChanged(AuthNpmChanged event, Emitter emit) {
    _npm = event.npm;
  }

  void _onPasswordChanged(AuthPasswordChanged event, Emitter emit) {
    _password = event.password;
  }

  void _onPasswordVisibilityToggled(
    AuthPasswordVisibilityToggled event,
    Emitter emit,
  ) {
    _passwordVisible = !_passwordVisible;
  }

  void _onRememberMeToggled(AuthRememberMeToggled event, Emitter emit) {
    _rememberMe = event.value;
  }

  Future<void> _onSubmitted(AuthSubmitted event, Emitter emit) async {
    if (_npm.isEmpty || _password.isEmpty) {
      emit(const AuthError('NPM dan password wajib diisi'));
      return;
    }
    if (!RegExp(r'^\d{11}$').hasMatch(_npm)) {
      emit(const AuthError('NPM harus 11 digit angka'));
      return;
    }
    try {
      final AuthEntity user = await _getAuth(npm: _npm, password: _password);
      emit(AuthLoading());
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(const AuthError('NPM atau password salah'));
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter emit) {
    _npm = '';
    _password = '';
    _passwordVisible = false;
    _rememberMe = false;
    emit(const AuthInitial());
  }
}
