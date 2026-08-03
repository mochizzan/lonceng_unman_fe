// lib/features/auth/data/models/auth_model.dart
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.npm,
    required super.token,
    required super.expiresAt,
  });

  factory AuthModel.fromMap(Map<String, dynamic> map) {
    return AuthModel(
      npm: map['npm'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'npm': npm,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
