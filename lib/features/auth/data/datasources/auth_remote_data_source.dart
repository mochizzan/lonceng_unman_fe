// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:lonceng_unman_fe/features/auth/data/models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String npm, required String password});
}

/// Real HTTP implementation via ApiClient.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthModel> login({
    required String npm,
    required String password,
  }) async {
    // ApiClient.post() parses the envelope and returns the inner `data` map.
    final data = await apiClient.post(
      '/api/v1/lms/login',
      body: lmsCredentialBody(npm: npm, password: password),
    );
    // Login failure returns HTTP 200 with data.success = false.
    final success = data['success'] as bool? ?? false;
    if (!success) {
      final message = data['message'] as String? ?? 'Login gagal';
      throw AuthException(message);
    }
    return AuthModel(npm: npm, password: password);
  }
}
