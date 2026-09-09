// Tests for the pull-refresh debounce branch in
// DataInitializationRemoteDataSource (spec §5.5 poin 2):
// a debounced pull-refresh takes the light (get-only) branch, an undebounced
// pull-refresh and a fresh login take the heavy branch.
//
// Hand-written fakes only — no mockito/mocktail (repo convention).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/domain/metadata_entity.dart';
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
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

const _npm = '2211700006';
const _password = 'Izzan027';

// ─── Sample entities ──────────────────────────────────────────────────────

StudentProfileModel _sampleProfile() => const StudentProfileModel(
  nim: _npm,
  nisn: '',
  nik: '',
  namaMahasiswa: 'Test User',
  programStudi: 'SI',
  semester: 'GANJIL',
  kelas: 'A',
  statusKonversi: '2022',
);

KrsEntity _sampleKrs() => const KrsEntity(
  krs: KrsDataEntity(
    mahasiswa: MahasiswaEntity(
      nama: 'Test User',
      npm: _npm,
      programStudi: 'SI',
    ),
    periode: PeriodeEntity(tahunAjaran: '2024/2025', semester: 'Ganjil'),
    mataKuliah: [
      MataKuliahKrsEntity(
        kode: 'IF101',
        nama: 'Algoritma',
        sks: 3,
        hari: 'Senin',
        jamMulai: '08:00',
        jamSelesai: '10:30',
        dosen: 'Dosen A',
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

KhsEntity _sampleKhs(String semester) => KhsEntity(
  khs: KhsDataEntity(
    mahasiswa: const MahasiswaEntity(
      nama: 'Test User',
      npm: _npm,
      programStudi: 'SI',
    ),
    periode: PeriodeEntity(tahunAjaran: '2024/2025', semester: semester),
    mataKuliah: const [
      MataKuliahKhsEntity(
        kode: 'IF101',
        nama: 'Algoritma',
        sks: 3,
        nilai: 'A',
        mutu: 12,
        dosen: 'Dosen A',
      ),
    ],
    rekapitulasi: const RekapitulasiEntity(
      totalSks: 3,
      totalMutu: 12,
      ipk: 4.0,
    ),
  ),
  metadata: const MetadataEntity(
    extractedAt: 'now',
    sourceFile: 'khs.pdf',
    fileSize: 1,
  ),
);

const _twoSemesters = [
  KhsSemesterEntity(tahunAjaran: '2024/2025', semester: 'Ganjil', sks: 20),
  KhsSemesterEntity(tahunAjaran: '2024/2025', semester: 'Genap', sks: 22),
];

const _oneSemester = [
  KhsSemesterEntity(tahunAjaran: '2024/2025', semester: 'Ganjil', sks: 20),
];

// ─── Fakes ────────────────────────────────────────────────────────────────

/// Fake debounce where the test controls [shouldUseLight] and observes
/// [touch] / [shouldUseLight] call counts.
class _FakeDebounce extends PullRefreshDebounce {
  _FakeDebounce();

  bool useLight = false;
  int shouldUseLightCalls = 0;
  int touchCalls = 0;
  String? lastShouldUseLightNpm;
  String? lastTouchNpm;

  @override
  bool shouldUseLight(String npm, [DateTime? now]) {
    shouldUseLightCalls++;
    lastShouldUseLightNpm = npm;
    return useLight;
  }

  @override
  void touch(String npm, [DateTime? now]) {
    touchCalls++;
    lastTouchNpm = npm;
  }
}

class _FakeKrsRepo implements KrsRepository {
  int downloadCalls = 0;
  int extractCalls = 0;
  int getDataCalls = 0;
  final List<bool> getDataForceRefresh = [];

  /// When set, [getKrsData] throws it instead of returning data.
  Object? getDataError;

  @override
  Future<void> downloadKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    downloadCalls++;
  }

  @override
  Future<void> extractKrs({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    extractCalls++;
  }

  @override
  Future<KrsEntity> getKrsData({
    required String npm,
    bool forceRefresh = false,
  }) async {
    getDataCalls++;
    getDataForceRefresh.add(forceRefresh);
    if (getDataError != null) throw getDataError!;
    return _sampleKrs();
  }
}

class _FakeKhsRepo implements KhsRepository {
  int semestersCalls = 0;
  int downloadCalls = 0;
  int extractCalls = 0;
  int getDataCalls = 0;
  final List<String> getDataSemesters = [];
  final List<bool> getDataForceRefresh = [];

  List<KhsSemesterEntity> semesters = _twoSemesters;

  /// When set, [getSemesters] throws it instead of returning data.
  Object? semestersError;

  /// Semester names for which [getKhsData] throws [failingError].
  Set<String> failingSemesters = const {};
  Object failingError = Exception('khs data boom');

  @override
  Future<List<KhsSemesterEntity>> getSemesters({
    required String npm,
    required String password,
  }) async {
    semestersCalls++;
    if (semestersError != null) throw semestersError!;
    return semesters;
  }

  @override
  Future<void> downloadKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  }) async {
    downloadCalls++;
  }

  @override
  Future<void> extractKhs({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  }) async {
    extractCalls++;
  }

  @override
  Future<KhsEntity> getKhsData({
    required String npm,
    required String tahunAjaran,
    required String semester,
    bool forceRefresh = false,
  }) async {
    getDataCalls++;
    getDataSemesters.add(semester);
    getDataForceRefresh.add(forceRefresh);
    if (failingSemesters.contains(semester)) throw failingError;
    return _sampleKhs(semester);
  }
}

class _FakeProfileDataSource implements StudentProfileRemoteDataSource {
  int scrapeCalls = 0;
  int getProfileCalls = 0;
  final List<bool> getProfileForceRefresh = [];

  /// When set, [getProfile] throws it instead of returning data.
  Object? getProfileError;

  @override
  Future<void> scrapeProfile({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    scrapeCalls++;
  }

  @override
  Future<StudentProfileModel> getProfile({
    required String npm,
    required String password,
    bool forceRefresh = false,
  }) async {
    getProfileCalls++;
    getProfileForceRefresh.add(forceRefresh);
    if (getProfileError != null) throw getProfileError!;
    return _sampleProfile();
  }

  @override
  Future<StudentProfileModel> getProfilePreview({
    required String npm,
    required String password,
  }) async {
    return _sampleProfile();
  }
}

class _FakePhotoService extends PhotoService {
  _FakePhotoService() : super();

  int fetchCalls = 0;
  Uint8List? bytesToReturn = Uint8List.fromList([1, 2, 3]);

  /// When set, [fetchPhoto] throws it instead of returning bytes.
  Object? fetchError;

  @override
  Future<Uint8List?> fetchPhoto({
    required String npm,
    required String password,
  }) async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return bytesToReturn;
  }
}

/// In-memory avatar cache — no Hive.
class _FakeAvatarCache extends AvatarCacheService {
  final Map<String, Uint8List> store = {};
  int saveCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveAvatar({
    required String npm,
    required Uint8List bytes,
  }) async {
    saveCalls++;
    store[npm] = bytes;
  }

  @override
  Future<Uint8List?> loadAvatar(String npm) async => store[npm];

  @override
  Future<void> deleteAvatar(String npm) async => store.remove(npm);

  @override
  bool hasAvatar(String npm) => store.containsKey(npm);
}

/// Builds a datasource wired to fakes only — no Services.get lookups.
class _Fixture {
  _Fixture() {
    krsRepo = _FakeKrsRepo();
    khsRepo = _FakeKhsRepo();
    profileDs = _FakeProfileDataSource();
    photo = _FakePhotoService();
    avatarCache = _FakeAvatarCache();
    avatarCubit = AvatarCubit(cache: avatarCache);
    debounce = _FakeDebounce();
    datasource = DataInitializationRemoteDataSource(
      getKrs: GetKrs(krsRepo),
      getKhs: GetKhs(khsRepo),
      profileDataSource: profileDs,
      photoService: photo,
      avatarCache: avatarCache,
      avatarCubit: avatarCubit,
      debounce: debounce,
    );
    addTearDown(avatarCubit.close);
  }

  late final _FakeKrsRepo krsRepo;
  late final _FakeKhsRepo khsRepo;
  late final _FakeProfileDataSource profileDs;
  late final _FakePhotoService photo;
  late final _FakeAvatarCache avatarCache;
  late final AvatarCubit avatarCubit;
  late final _FakeDebounce debounce;
  late final DataInitializationRemoteDataSource datasource;
}

Future<List<DataInitProgress>> _run(_Fixture f, {bool isPullRefresh = true}) {
  return f.datasource
      .initialize(
        npm: _npm,
        password: _password,
        forceRefresh: true,
        isPullRefresh: isPullRefresh,
      )
      .toList();
}

void main() {
  group('DataInitializationRemoteDataSource pull-refresh branches', () {
    group('cabang ringan (debounced)', () {
      test('skip scrape/download/extract, emit urutan ringan lalu completed, '
          'sliding touch (A1)', () async {
        final f = _Fixture();
        f.debounce.useLight = true;

        final events = await _run(f);
        final statuses = events.map((e) => e.status).toList();

        expect(statuses, [
          DataInitStatus.gettingProfile,
          DataInitStatus.fetchingPhoto,
          DataInitStatus.fetchingKrsData,
          DataInitStatus.fetchingKhsSemesters,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.completed,
        ]);

        // Metode berat TIDAK PERNAH dipanggil.
        expect(f.profileDs.scrapeCalls, 0);
        expect(f.krsRepo.downloadCalls, 0);
        expect(f.krsRepo.extractCalls, 0);
        expect(f.khsRepo.downloadCalls, 0);
        expect(f.khsRepo.extractCalls, 0);

        // Metode ringan dipanggil sesuai urutan.
        expect(f.profileDs.getProfileCalls, 1);
        expect(f.photo.fetchCalls, 1);
        expect(f.krsRepo.getDataCalls, 1);
        expect(f.khsRepo.semestersCalls, 1);
        expect(f.khsRepo.getDataCalls, 2);

        // Cabang ringan tetap hit network (forceRefresh: true).
        expect(f.profileDs.getProfileForceRefresh, [true]);
        expect(f.krsRepo.getDataForceRefresh, [true]);
        expect(f.khsRepo.getDataForceRefresh, [true, true]);

        // Detail semester terbawa per fetchingKhsData.
        final khsDetails = events
            .where((e) => e.status == DataInitStatus.fetchingKhsData)
            .map((e) => e.detail)
            .toList();
        expect(khsDetails, ['2024/2025 Ganjil', '2024/2025 Genap']);

        // Pembukuan debounce sliding 3m (A1, check-then-touch): dicek sekali
        // terhadap jangkar lama, lalu touch geser ke now — baik light maupun heavy.
        expect(f.debounce.shouldUseLightCalls, 1);
        expect(f.debounce.lastShouldUseLightNpm, _npm);
        expect(f.debounce.touchCalls, 1);
        expect(f.debounce.lastTouchNpm, _npm);

        // Tail pipeline (cache foto) tetap jalan.
        expect(f.avatarCache.saveCalls, 1);
      });
    });

    group('jalur berat (tidak debounced)', () {
      test('urutan berat utuh + touch tepat sekali saat '
          'isPullRefresh true', () async {
        final f = _Fixture();
        f.debounce.useLight = false;
        f.khsRepo.semesters = _oneSemester;

        final events = await _run(f);
        final statuses = events.map((e) => e.status).toList();

        expect(statuses, [
          DataInitStatus.scrapingProfile,
          DataInitStatus.scrapingProfile,
          DataInitStatus.gettingProfile,
          DataInitStatus.fetchingPhoto,
          DataInitStatus.downloadingKrs,
          DataInitStatus.extractingKrs,
          DataInitStatus.fetchingKrsData,
          DataInitStatus.fetchingKhsSemesters,
          DataInitStatus.downloadingKhs,
          DataInitStatus.extractingKhs,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.completed,
        ]);

        expect(
          events
              .firstWhere((e) => e.status == DataInitStatus.downloadingKhs)
              .detail,
          '2024/2025 Ganjil',
        );

        expect(f.profileDs.scrapeCalls, 2);
        expect(f.krsRepo.downloadCalls, 1);
        expect(f.krsRepo.extractCalls, 1);
        expect(f.khsRepo.downloadCalls, 1);
        expect(f.khsRepo.extractCalls, 1);

        expect(f.debounce.shouldUseLightCalls, 1);
        expect(f.debounce.touchCalls, 1);
        expect(f.debounce.lastTouchNpm, _npm);
      });
    });

    group('fresh login (isPullRefresh false)', () {
      test('debounce tidak dicek sama sekali, jalur berat jalan, '
          'touch tidak dipanggil', () async {
        final f = _Fixture();
        f.khsRepo.semesters = _oneSemester;

        final events = await _run(f, isPullRefresh: false);
        final statuses = events.map((e) => e.status).toList();

        expect(statuses, [
          DataInitStatus.scrapingProfile,
          DataInitStatus.scrapingProfile,
          DataInitStatus.gettingProfile,
          DataInitStatus.fetchingPhoto,
          DataInitStatus.downloadingKrs,
          DataInitStatus.extractingKrs,
          DataInitStatus.fetchingKrsData,
          DataInitStatus.fetchingKhsSemesters,
          DataInitStatus.downloadingKhs,
          DataInitStatus.extractingKhs,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.completed,
        ]);

        expect(f.debounce.shouldUseLightCalls, 0);
        expect(f.debounce.touchCalls, 0);
        expect(f.profileDs.scrapeCalls, 2);
      });
    });

    group('failure cabang ringan', () {
      test('getProfile throw → stream melempar step profile_get '
          '(BLoC memetakan ke Failure)', () async {
        final f = _Fixture();
        f.debounce.useLight = true;
        f.profileDs.getProfileError = Exception('profile boom');

        await expectLater(
          _run(f),
          throwsA(
            isA<DataInitStepException>().having(
              (e) => e.step,
              'step',
              'profile_get',
            ),
          ),
        );

        // Pipeline berhenti: tidak ada get lanjutan. A1: touch sudah
        // terjadi di awal dispatcher sebelum outcome diketahui.
        expect(f.photo.fetchCalls, 0);
        expect(f.krsRepo.getDataCalls, 0);
        expect(f.khsRepo.semestersCalls, 0);
        expect(f.debounce.touchCalls, 1);
      });

      test('getKrsData throw → krsEmpty lalu lanjut ke KHS', () async {
        final f = _Fixture();
        f.debounce.useLight = true;
        f.krsRepo.getDataError = Exception('krs boom');

        final events = await _run(f);
        final statuses = events.map((e) => e.status).toList();

        expect(statuses, [
          DataInitStatus.gettingProfile,
          DataInitStatus.fetchingPhoto,
          DataInitStatus.fetchingKrsData,
          DataInitStatus.krsEmpty,
          DataInitStatus.fetchingKhsSemesters,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.completed,
        ]);
        expect(f.khsRepo.getDataCalls, 2);
      });

      test('getSemesters throw → khsEmpty lalu completed', () async {
        final f = _Fixture();
        f.debounce.useLight = true;
        f.khsRepo.semestersError = Exception('semesters boom');

        final events = await _run(f);
        final statuses = events.map((e) => e.status).toList();

        expect(statuses, [
          DataInitStatus.gettingProfile,
          DataInitStatus.fetchingPhoto,
          DataInitStatus.fetchingKrsData,
          DataInitStatus.fetchingKhsSemesters,
          DataInitStatus.khsEmpty,
          DataInitStatus.completed,
        ]);
        expect(f.khsRepo.getDataCalls, 0);
      });

      test('satu semester getKhsData throw → semester lain tetap diproses + '
          'khsEmpty di akhir (sentinel ::error::fetch view merah)', () async {
        final f = _Fixture();
        f.debounce.useLight = true;
        f.khsRepo.failingSemesters = {'Ganjil'};

        final events = await _run(f);
        final statuses = events.map((e) => e.status).toList();

        expect(statuses, [
          DataInitStatus.gettingProfile,
          DataInitStatus.fetchingPhoto,
          DataInitStatus.fetchingKrsData,
          DataInitStatus.fetchingKhsSemesters,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.fetchingKhsData,
          DataInitStatus.khsEmpty,
          DataInitStatus.completed,
        ]);
        expect(f.khsRepo.getDataCalls, 2);
        expect(f.khsRepo.getDataSemesters, ['Ganjil', 'Genap']);
        // Sentinel carries failed semester detail so view paints merah.
        final errDetail = events
            .where(
              (e) =>
                  e.status == DataInitStatus.fetchingKhsData &&
                  (e.detail ?? '').contains('::error::fetch'),
            )
            .map((e) => e.detail)
            .toList();
        expect(errDetail, isNotEmpty);
      });

      test('AuthException dari getProfile ringan tetap rethrow '
          '(bukan jadi empty)', () async {
        final f = _Fixture();
        f.debounce.useLight = true;
        f.profileDs.getProfileError = const AuthException(
          'Sesi telah berakhir. Silakan login ulang.',
        );

        await expectLater(
          _run(f),
          throwsA(
            isA<DataInitStepException>()
                .having(
                  (e) => e.originalError,
                  'originalError',
                  isA<AuthException>(),
                )
                .having((e) => e.step, 'step', 'profile_get'),
          ),
        );
      });
    });
  });
}
