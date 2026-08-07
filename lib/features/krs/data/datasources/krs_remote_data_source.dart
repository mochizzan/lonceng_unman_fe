import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';

abstract class KrsRemoteDataSource {
  Future<void> downloadKrs({required String npm, required String password});
  Future<void> extractKrs({required String npm, required String password});
  Future<KrsModel> getKrsData({required String npm});
}

/// Real HTTP implementation via ApiClient.
class KrsRemoteDataSourceImpl implements KrsRemoteDataSource {
  final ApiClient apiClient;
  const KrsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> downloadKrs({
    required String npm,
    required String password,
  }) async {
    await apiClient.post(
      '/api/v1/lms/krs',
      body: lmsCredentialBody(npm: npm, password: password),
    );
  }

  @override
  Future<void> extractKrs({
    required String npm,
    required String password,
  }) async {
    await apiClient.post(
      '/api/v1/lms/krs/extract',
      body: lmsCredentialBody(npm: npm, password: password),
    );
  }

  @override
  Future<KrsModel> getKrsData({required String npm}) async {
    final response = await apiClient.post(
      '/api/v1/lms/krs/data',
      body: {'npm': npm},
    );
    return KrsModel.fromJson(response);
  }
}
