import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';

abstract class KhsRemoteDataSource {
  Future<List<KhsSemesterModel>> getSemesters({
    required String npm,
    required String password,
  });

  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  });

  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  });

  Future<KhsModel> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
  });
}

/// Real HTTP implementation via ApiClient.
class KhsRemoteDataSourceImpl implements KhsRemoteDataSource {
  final ApiClient apiClient;
  const KhsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<KhsSemesterModel>> getSemesters({
    required String npm,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/api/v1/lms/khs/semesters',
      body: lmsCredentialBody(npm: npm, password: password),
    );
    final data = response;
    final semesters = data['semesters'] as List<dynamic>? ?? [];
    return semesters
        .map((e) => KhsSemesterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) async {
    await apiClient.post(
      '/api/v1/lms/khs',
      body: lmsCredentialBody(
        npm: npm,
        password: password,
        tahunAjaran: tahunAjaran,
        semester: semester,
      ),
    );
  }

  @override
  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) async {
    await apiClient.post(
      '/api/v1/lms/khs/extract',
      body: lmsCredentialBody(
        npm: npm,
        password: password,
        tahunAjaran: tahunAjaran,
        semester: semester,
      ),
    );
  }

  @override
  Future<KhsModel> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    final response = await apiClient.post(
      '/api/v1/lms/khs/data',
      body: {'npm': npm, 'tahun_ajaran': tahunAjaran, 'semester': semester},
    );
    return KhsModel.fromJson(response);
  }
}
