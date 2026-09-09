// OPSI B: foto harus eager-cache segera setelah fetch, agar pause KRS/KHS tidak hilangkan foto
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_debounce.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/features/khs/domain/repositories/khs_repository.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';
import 'package:lonceng_unman_fe/features/krs/domain/repositories/krs_repository.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';
import 'package:lonceng_unman_fe/core/domain/metadata_entity.dart';

const _npm = '2211700006';
const _pwd = 'x';
StudentProfileModel _profile() => const StudentProfileModel(
  nim: _npm,
  nisn: '',
  nik: '',
  namaMahasiswa: 'A',
  programStudi: 'SI',
  semester: 'GANJIL',
  kelas: 'A',
  statusKonversi: '2022',
);
KrsEntity _krs() => const KrsEntity(
  krs: KrsDataEntity(
    mahasiswa: MahasiswaEntity(nama: 'A', npm: _npm, programStudi: 'SI'),
    periode: PeriodeEntity(tahunAjaran: '2024/2025', semester: 'Ganjil'),
    mataKuliah: [
      MataKuliahKrsEntity(
        kode: 'IF1',
        nama: 'A',
        sks: 3,
        hari: 'Senin',
        jamMulai: '08:00',
        jamSelesai: '10:30',
        dosen: 'D',
      ),
    ],
    totalSks: 3,
  ),
  metadata: MetadataEntity(
    extractedAt: 'now',
    sourceFile: 'krs.pdf',
    fileSize: 1,
  ),
);

class _FakeKrs implements KrsRepository {
  bool failDownload = false;
  @override
  Future<void> downloadKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (failDownload)
      throw DataInitStepException(
        'krs_download',
        'net',
        const NetworkException('offline'),
      );
  }

  @override
  Future<void> extractKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {}
  @override
  Future<KrsEntity> getKrsData({
    required String npm,
    bool forceRefresh = false,
  }) async => _krs();
}

class _FakeKhs implements KhsRepository {
  @override
  Future<List<KhsSemesterEntity>> getSemesters({
    required String npm,
    required String password,
  }) async => [
    const KhsSemesterEntity(
      tahunAjaran: '2024/2025',
      semester: 'Ganjil',
      sks: 20,
    ),
  ];
  @override
  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  }) async {}
  @override
  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  }) async {}
  @override
  Future<KhsEntity> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  }) async => KhsEntity(
    khs: KhsDataEntity(
      mahasiswa: const MahasiswaEntity(
        nama: 'A',
        npm: _npm,
        programStudi: 'SI',
      ),
      periode: PeriodeEntity(tahunAjaran: tahunAjaran, semester: semester),
      mataKuliah: const [
        MataKuliahKhsEntity(
          kode: 'IF1',
          nama: 'A',
          sks: 3,
          nilai: 'A',
          mutu: 12,
          dosen: 'D',
        ),
      ],
      rekapitulasi: const RekapitulasiEntity(
        totalSks: 3,
        totalMutu: 12,
        ipk: 4,
      ),
    ),
    metadata: const MetadataEntity(
      extractedAt: 'now',
      sourceFile: 'khs.pdf',
      fileSize: 1,
    ),
  );
}

class _FakeProfile implements StudentProfileRemoteDataSource {
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
  }) async => _profile();
  @override
  Future<StudentProfileModel> getProfilePreview({
    required String npm,
    required String password,
  }) async => _profile();
}

class _FakePhoto extends PhotoService {
  _FakePhoto() : super();
  Uint8List? ret = Uint8List.fromList([10, 20, 30]);
  @override
  Future<Uint8List?> fetchPhoto({
    required String npm,
    required String password,
  }) async => ret;
}

class _FakeAvatar extends AvatarCacheService {
  final Map<String, Uint8List> store = {};
  int saves = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> saveAvatar({
    required String npm,
    required Uint8List bytes,
  }) async {
    saves++;
    store[npm] = bytes;
  }

  @override
  Future<Uint8List?> loadAvatar(String npm) async => store[npm];
  @override
  Future<void> deleteAvatar(String npm) async => store.remove(npm);
  @override
  bool hasAvatar(String npm) => store.containsKey(npm);
}

void main() {
  test(
    'eager: pause di krs_download tetap simpan foto + emit ke AvatarCubit, retry/deferred completed tetap ada foto',
    () async {
      final krs = _FakeKrs()..failDownload = true;
      final khs = _FakeKhs();
      final profile = _FakeProfile();
      final photo = _FakePhoto();
      final cache = _FakeAvatar();
      final cubit = AvatarCubit(cache: cache);
      // bootstrap bind ke npm agar onPhotoCached same-npm path teruji
      await cubit.bindNpm(_npm);
      expect(cubit.state.bytes, isNull);
      final ds = DataInitializationRemoteDataSource(
        getKrs: GetKrs(krs),
        getKhs: GetKhs(khs),
        profileDataSource: profile,
        photoService: photo,
        avatarCache: cache,
        avatarCubit: cubit,
        debounce: PullRefreshDebounce(),
      );
      addTearDown(cubit.close);

      // _initializeHeavy should rethrow krs_download network -> pause
      await expectLater(
        ds.initialize(npm: _npm, password: _pwd, isPullRefresh: false).toList(),
        throwsA(
          isA<DataInitStepException>().having(
            (e) => e.step,
            'step',
            'krs_download',
          ),
        ),
      );

      // BUG lama: 0 saves karena tail tidak jalan. Fix OPSI B: 1 save eager sebelum KRS
      expect(
        cache.saves,
        1,
        reason: 'foto eager harus sudah tersimpan meski pause KRS',
      );
      expect(cache.store[_npm], Uint8List.fromList([10, 20, 30]));
      expect(cubit.state, isA<AvatarReady>());
      expect(
        (cubit.state as AvatarReady).bytes,
        Uint8List.fromList([10, 20, 30]),
      );

      // Simulate retry: heavy sukses (tanpa fail) tetap foto ada (idempoten tail)
      krs.failDownload = false;
      final events = await ds
          .initialize(npm: _npm, password: _pwd, isPullRefresh: false)
          .toList();
      expect(events.last.status, DataInitStatus.completed);
      expect(
        cache.saves,
        2,
        reason:
            'retry sukses: 1 eager pertama (pause) + 1 eager retry (tail skip)',
      );
      expect(cubit.state.bytes, Uint8List.fromList([10, 20, 30]));
    },
  );

  test('eager: foto kosong/null tidak trigger save', () async {
    final krs = _FakeKrs();
    final khs = _FakeKhs();
    final profile = _FakeProfile();
    final photo = _FakePhoto()..ret = null;
    final cache = _FakeAvatar();
    final cubit = AvatarCubit(cache: cache);
    await cubit.bindNpm(_npm);
    final ds = DataInitializationRemoteDataSource(
      getKrs: GetKrs(krs),
      getKhs: GetKhs(khs),
      profileDataSource: profile,
      photoService: photo,
      avatarCache: cache,
      avatarCubit: cubit,
      debounce: PullRefreshDebounce(),
    );
    addTearDown(cubit.close);
    final events = await ds
        .initialize(npm: _npm, password: _pwd, isPullRefresh: false)
        .toList();
    expect(
      events.map((e) => e.status).contains(DataInitStatus.photoEmpty),
      true,
    );
    expect(cache.saves, 0);
    expect(cubit.state.bytes, isNull);
  });
}
