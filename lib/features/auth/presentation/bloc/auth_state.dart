import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/student_profile/domain/entities/student_profile_entity.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthAuthenticated extends AuthState {
  final AuthEntity user;
  const AuthAuthenticated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;
}

class AuthError extends AuthState {
  final String message;
  final Object? error;
  const AuthError(this.message, {this.error});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Displayed when a student profile has been scraped and requires user
/// confirmation before the account is fully authenticated.
class AuthProfileReview extends AuthState {
  final StudentProfileEntity profile;
  final String npm;
  final String password;

  const AuthProfileReview(this.profile, this.npm, this.password);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthProfileReview &&
          runtimeType == other.runtimeType &&
          profile == other.profile &&
          npm == other.npm &&
          password == other.password;

  @override
  int get hashCode => Object.hash(profile, npm, password);
}
