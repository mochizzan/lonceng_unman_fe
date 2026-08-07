// lib/features/auth/data/models/auth_model.dart
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({required super.npm, required super.password});

  factory AuthModel.fromMap(Map<String, dynamic> map) {
    return AuthModel(
      npm: map['npm'] as String,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'npm': npm, 'password': password};
  }
}
