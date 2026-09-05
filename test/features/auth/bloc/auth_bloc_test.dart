import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

class FakeGetAuth implements GetAuth {
  final AuthEntity result;
  final Exception? error;
  FakeGetAuth(this.result, [this.error]);

  @override
  AuthRepository get repository =>
      throw UnsupportedError('repository not needed for tests');

  @override
  Future<AuthEntity> call({required String npm, required String password}) {
    if (error != null) throw error!;
    return Future.value(result);
  }
}

/// No-op save credentials for tests.
class FakeSaveAuthCredentials implements SaveAuthCredentials {
  @override
  Future<void> call({required String npm, required String password}) async {}
}

/// No-op load credentials for tests.
class FakeLoadAuthCredentials implements LoadAuthCredentials {
  @override
  Future<Map<String, String>?> call() async => null;
}

/// No-op student profile cache service for tests.
class FakeStudentProfileCacheService implements StudentProfileCacheService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveProfile({
    required String npm,
    required Map<String, dynamic> profileData,
  }) async {}

  @override
  Future<Map<String, dynamic>?> loadProfile({required String npm}) async =>
      null;

  @override
  bool hasProfile({required String npm}) => false;

  @override
  Future<void> clearProfile({required String npm}) async {}

  @override
  Future<void> clearAll() async {}
}

/// No-op academic cache service for tests.
class FakeAcademicCacheService implements AcademicCacheService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> saveCredentials({
    required String npm,
    required String password,
  }) async {}
  @override
  Future<Map<String, String>?> loadCredentials() async => null;
  @override
  Future<Map<String, String>?> loadCredentialsByNpm(String npm) async => null;
  @override
  bool hasCredentials() => false;
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<void> saveKrsData({
    required String npm,
    required Map<String, dynamic> data,
  }) async {}
  @override
  Future<Map<String, dynamic>?> loadKrsData({required String npm}) async =>
      null;
  @override
  bool hasKrsData({required String npm}) => false;
  @override
  Future<void> saveKhsList({
    required String npm,
    required List<dynamic> data,
  }) async {}
  @override
  Future<List<dynamic>?> loadKhsList({required String npm}) async => null;
  @override
  bool hasKhsList({required String npm}) => false;
  @override
  Future<void> saveKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
    required Map<String, dynamic> data,
  }) async {}
  @override
  Future<Map<String, dynamic>?> loadKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async => null;
  @override
  Future<bool> hasKhsDataSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async => false;
  @override
  bool hasAcademicData({required String npm}) => false;
  @override
  Future<void> clearKrsData() async {}
  @override
  Future<void> clearKhsData() async {}
  @override
  Future<void> clearAcademicData() async {}
  @override
  Future<void> clearAll() async {}
}

/// Fake remote data source that returns a minimal test model.
class FakeStudentProfileRemoteDataSource
    implements StudentProfileRemoteDataSource {
  @override
  Future<void> scrapeProfile({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {}

  @override
  Future<StudentProfileModel> getProfile({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    return const StudentProfileModel(
      nim: '21081010001',
      nisn: '',
      nik: '',
      namaMahasiswa: 'Test User',
      programStudi: 'SI',
      semester: 'GANJIL',
      kelas: 'Teknik',
      statusKonversi: '2022',
    );
  }

  @override
  Future<StudentProfileModel> getProfilePreview({
    required String npm,
    required String password,
  }) async {
    return const StudentProfileModel(
      nim: '21081010001',
      nisn: '',
      nik: '',
      namaMahasiswa: 'Test User',
      programStudi: 'SI',
      semester: 'GANJIL',
      kelas: 'Teknik',
      statusKonversi: '2022',
    );
  }
}

void main() {
  final authEntity = AuthEntity(npm: '21081010001', password: 'testpass');

  AuthBloc makeBloc(GetAuth getAuth) => AuthBloc(
    getAuth,
    saveCredentials: FakeSaveAuthCredentials(),
    loadCredentials: FakeLoadAuthCredentials(),
    profileDataSource: FakeStudentProfileRemoteDataSource(),
    profileCacheService: FakeStudentProfileCacheService(),
    academicCacheService: FakeAcademicCacheService(),
  );

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthProfileReview] on valid submit',
      build: () => makeBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [
        AuthLoading(),
        AuthProfileReview(
          const StudentProfileModel(
            nim: '21081010001',
            nisn: '',
            nik: '',
            namaMahasiswa: 'Test User',
            programStudi: 'SI',
            semester: 'GANJIL',
            kelas: 'Teknik',
            statusKonversi: '2022',
          ),
          '21081010001',
          'testpass',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is empty',
      build: () => makeBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM wajib diisi')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when password is empty',
      build: () => makeBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('Password wajib diisi')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthProfileReview] when NPM is 10 digits (valid edge)',
      build: () => makeBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('1234567890'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [
        AuthLoading(),
        AuthProfileReview(
          const StudentProfileModel(
            nim: '21081010001',
            nisn: '',
            nik: '',
            namaMahasiswa: 'Test User',
            programStudi: 'SI',
            semester: 'GANJIL',
            kelas: 'Teknik',
            statusKonversi: '2022',
          ),
          '1234567890',
          'testpass',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is not 10-11 digits',
      build: () => makeBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 10-11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM has non-numeric characters',
      build: () => makeBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123456789a'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 10-11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when login throws',
      build: () => makeBloc(
        FakeGetAuth(authEntity, NetworkException('Tidak ada koneksi')),
      ),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(const AuthPasswordChanged('testpass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), const AuthError('Tidak ada koneksi')],
    );
  });
}
