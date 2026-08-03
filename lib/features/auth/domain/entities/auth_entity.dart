/// AuthEntity — represents an authenticated user session.
class AuthEntity {
  final String npm;
  final String token;
  final DateTime expiresAt;

  const AuthEntity({
    required this.npm,
    required this.token,
    required this.expiresAt,
  });
}
