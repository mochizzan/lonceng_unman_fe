/// AuthEvent hierarchy for the authentication BLoC.
///
/// Each event represents a user-driven interaction or lifecycle signal
/// flowing into the auth BLoC. Manual equality (`==` / `hashCode`) is
/// implemented so that events can be compared and used as map keys
/// without the `equatable` package.
abstract class AuthEvent {
  const AuthEvent();
}

class AuthNpmChanged extends AuthEvent {
  final String npm;
  const AuthNpmChanged(this.npm);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthNpmChanged &&
          runtimeType == other.runtimeType &&
          npm == other.npm;

  @override
  int get hashCode => npm.hashCode;
}

class AuthPasswordChanged extends AuthEvent {
  final String password;
  const AuthPasswordChanged(this.password);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthPasswordChanged &&
          runtimeType == other.runtimeType &&
          password == other.password;

  @override
  int get hashCode => password.hashCode;
}

class AuthSubmitted extends AuthEvent {
  const AuthSubmitted();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSubmitted && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthLogoutRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
