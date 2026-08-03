// AuthEntity — represents an authenticated user session.
class AuthEntity {
  final String npm;
  final String token;
  final DateTime expiresAt;

  const AuthEntity({
    required this.npm,
    required this.token,
    required this.expiresAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthEntity &&
          runtimeType == other.runtimeType &&
          npm == other.npm &&
          token == other.token &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(npm, token, expiresAt);
}
