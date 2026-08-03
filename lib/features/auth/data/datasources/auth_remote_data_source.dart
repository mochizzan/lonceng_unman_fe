// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'package:lonceng_unman_fe/features/auth/data/models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String npm, required String password});
}

/// Stub implementation — returns mock on any 11-digit NPM.
/// Replace with real HTTP client when backend is available.
class StubAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthModel> login({
    required String npm,
    required String password,
  }) async {
    return AuthModel(
      npm: npm,
      token: 'mock_token',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
  }
}
