/// AuthEntity — represents an authenticated user session.
class AuthEntity {
  final String npm;
  final String password;

  const AuthEntity({required this.npm, required this.password});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthEntity &&
          runtimeType == other.runtimeType &&
          npm == other.npm &&
          password == other.password;

  @override
  int get hashCode => Object.hash(npm, password);
}
