import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/utils/network_error_classifier.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_debounce.dart';

/// Orchestrates the post-login data initialization pipeline.
///
/// Non-destructive: new data overwrites old cache entries directly.
/// Pipeline (home page):
///   Profile:
///   0. Scrape Profile (2x) → POST /api/v1/lms/student-profile
///   1. Get Profile         → POST /api/v1/lms/student-profile/data
///   1b. Fetch Photo        → POST /api/v1/lms/student-profile/photo
///   KRS:
///   2. Download KRS PDF   → POST /api/v1/lms/krs
///   3. Extract KRS        → POST /api/v1/lms/krs/extract
///   4. Fetch KRS data     → POST /api/v1/lms/krs/data
///   KHS:
///   5. Get KHS semesters  → POST /api/v1/lms/khs/semesters
///   6. Download KHS PDF   → POST /api/v1/lms/khs
///   7. Extract KHS        → POST /api/v1/lms/khs/extract
///   8. Fetch KHS data     → POST /api/v1/lms/khs/data
///
/// Login (1 call on login page):
///   POST /api/v1/lms/login
///
/// Total: 11 endpoint hits.
///
/// Pull-refresh debouncing: [initialize] dispatches on [isPullRefresh] +
/// [PullRefreshDebounce] — sliding 3-minute window, every pull [touch]es
/// the anchor at the START (A1) before branching. Pulls within 3m of the
/// last pull take [_initializeLight] (get-only, skips scrape/download/
/// extract); the first pull or any after ≥3m idle takes [_initializeHeavy]
/// (full pipeline, unchanged). Fresh login (isPullRefresh=false) never
/// consults or touches the debounce.
class DataInitializationRemoteDataSource {
  final GetKrs _getKrs;
  final GetKhs _getKhs;
  final StudentProfileRemoteDataSource _profileDataSource;
  final PhotoService _photoService;
  final AvatarCacheService _avatarCache;
  final AvatarCubit _avatarCubit;
  final PullRefreshDebounce _debounce;

  DataInitializationRemoteDataSource({
    required GetKrs getKrs,
    required GetKhs getKhs,
    required StudentProfileRemoteDataSource profileDataSource,
    PhotoService? photoService,
    AvatarCacheService? avatarCache,
    AvatarCubit? avatarCubit,
    PullRefreshDebounce? debounce,
  }) : _getKrs = getKrs,
       _getKhs = getKhs,
       _profileDataSource = profileDataSource,
       _photoService = photoService ?? Services.get<PhotoService>(),
       _avatarCache = avatarCache ?? Services.get<AvatarCacheService>(),
       _avatarCubit = avatarCubit ?? Services.get<AvatarCubit>(),
       _debounce = debounce ?? Services.get<PullRefreshDebounce>();

  /// Dispatcher: sliding 3m, check-then-touch (A1).
  ///
  /// Ordering kritis: `shouldUseLight` dulu terhadap jangkar LAMA, baru
  /// `touch` geser ke now. Jika dibalik, setiap pull jadi light selamanya.
  /// `touch` di AWAL bahkan bila pipeline gagal (A1). Fresh login tanpa cek/touch.
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) async* {
    debugPrint(
      '[DATA_INIT_DS] initialize() START — npm=$npm, forceRefresh=$forceRefresh, isPullRefresh=$isPullRefresh',
    );

    if (isPullRefresh) {
      final useLight = _debounce.shouldUseLight(npm);
      _debounce.touch(npm);
      if (useLight) {
        debugPrint(
          '[DATA_INIT_DS] initialize() → LIGHT branch (debounced, sliding 3m)',
        );
        yield* _initializeLight(npm: npm, password: password);
        return;
      }
      debugPrint(
        '[DATA_INIT_DS] initialize() → HEAVY branch (pull-refresh, sliding 3m)',
      );
    } else {
      debugPrint('[DATA_INIT_DS] initialize() → HEAVY branch (fresh login)');
    }
    yield* _initializeHeavy(
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
    );
  }

  /// Jalur berat: pipeline penuh.
  /// Fase profile+foto inline; fase KRS/KHS didelegasikan ke helper bersama
  /// [_phaseKrs] / [_phaseKhsSemestersAndLoop] / [_khsSemesterSteps] agar
  /// tidak duplikat dengan [resumeFrom].
  Stream<DataInitProgress> _initializeHeavy({
    required String npm,
    required String password,
    required bool forceRefresh,
  }) async* {
    debugPrint(
      '[DATA_INIT_DS] _initializeHeavy() START — npm=$npm, forceRefresh=$forceRefresh',
    );

    // Step 0a/b + 1 + 1b inline — unik jalur berat
    debugPrint('[DATA_INIT_DS] Step 0a: scrapingProfile');
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    await _runStep(
      'profile_scrape_1',
      () => _profileDataSource.scrapeProfile(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
      ),
    );
    debugPrint('[DATA_INIT_DS] Step 0b: scrapingProfile (2nd)');
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    await _runStep(
      'profile_scrape_2',
      () => _profileDataSource.scrapeProfile(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
      ),
    );
    debugPrint('[DATA_INIT_DS] Step 1: gettingProfile');
    yield const DataInitProgress(DataInitStatus.gettingProfile);
    await _fetchProfileOrThrow(
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
    );
    debugPrint('[DATA_INIT_DS] Step 1b: fetchingPhoto');
    yield const DataInitProgress(DataInitStatus.fetchingPhoto);
    final photoBytes = await _fetchPhotoBestEffort(
      npm: npm,
      password: password,
    );
    final bool photoEagerCached = photoBytes != null && photoBytes.isNotEmpty;
    if (photoBytes == null || photoBytes.isEmpty) {
      yield const DataInitProgress(DataInitStatus.photoEmpty);
    } else {
      // OPSI B: eager cache — simpan segera agar pause di KRS/KHS tidak hilangkan foto
      await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
    }

    // KRS — inline agar yield status tetap urut (heavy dedup tidak pakai helper di sini)
    try {
      debugPrint('[DATA_INIT_DS] Step 2: downloadingKrs');
      yield const DataInitProgress(DataInitStatus.downloadingKrs);
      await _runStep(
        'krs_download',
        () => _getKrs.download(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        ),
      );
      _logStepOutcome(
        const DataInitStepOutcome(
          step: 'krs_download',
          result: DataInitStepResult.success,
        ),
      );
      debugPrint('[DATA_INIT_DS] Step 3: extractingKrs');
      yield const DataInitProgress(DataInitStatus.extractingKrs);
      await _runStep(
        'krs_extract',
        () => _getKrs.extract(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        ),
      );
      _logStepOutcome(
        const DataInitStepOutcome(
          step: 'krs_extract',
          result: DataInitStepResult.success,
        ),
      );
      debugPrint('[DATA_INIT_DS] Step 4: fetchingKrsData');
      yield const DataInitProgress(DataInitStatus.fetchingKrsData);
      final isKrsEmpty = await _fetchKrsDataOrEmpty(
        npm: npm,
        forceRefresh: forceRefresh,
      );
      if (isKrsEmpty) {
        yield const DataInitProgress(DataInitStatus.krsEmpty);
      }
    } catch (e) {
      if (isNetworkError(e)) rethrow;
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'krs',
          result: DataInitStepResult.error,
          message: e.toString(),
        ),
      );
      debugPrint('[DATA_INIT_DS] KRS fetch failed (non-fatal): $e');
      yield const DataInitProgress(DataInitStatus.krsEmpty);
    }

    // KHS — via helper bersama
    try {
      debugPrint('[DATA_INIT_DS] Step 5: fetchingKhsSemesters');
      yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
      // Helper melakukan fetch semesters + loop per semester
      await for (final p in _phaseKhsSemestersAndLoop(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
      )) {
        yield p;
      }
    } catch (e) {
      if (isNetworkError(e)) rethrow;
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'khs',
          result: DataInitStepResult.error,
          message: e.toString(),
        ),
      );
      debugPrint('[DATA_INIT_DS] KHS fetch failed (non-fatal): $e');
      yield const DataInitProgress(DataInitStatus.khsEmpty);
    }

    // Tail: skip jika sudah eager (hindari double save); tetap panggil bila foto null/empty tidak eager
    if (!photoEagerCached) {
      await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
    }
    debugPrint('[DATA_INIT_DS] Pipeline completed');
    yield const DataInitProgress(DataInitStatus.completed);
  }

  /// Cabang ringan pull-refresh (debounced): skip scrape/download/extract,
  /// langsung get dengan forceRefresh:true agar tetap hit network.
  ///
  /// Urutan: gettingProfile (wajib, rethrow) → fetchingPhoto (non-fatal) →
  /// blok KRS ringan (fetchingKrsData, non-fatal) → blok KHS ringan
  /// (fetchingKhsSemesters + fetchingKhsData per semester, non-fatal) →
  /// cache foto → completed. Semantik failure identik jalur berat.
  Stream<DataInitProgress> _initializeLight({
    required String npm,
    required String password,
  }) async* {
    debugPrint(
      '[DATA_INIT_DS] _initializeLight() START — npm=$npm (debounced, forceRefresh=true)',
    );

    // 1. Profile (WAJIB — gagal = pipeline berhenti, tanpa scrape)
    debugPrint('[DATA_INIT_DS] Light Step 1: gettingProfile');
    yield const DataInitProgress(DataInitStatus.gettingProfile);
    await _fetchProfileOrThrow(
      npm: npm,
      password: password,
      forceRefresh: true,
    );

    // 2. Foto Profil (opsional)
    debugPrint('[DATA_INIT_DS] Light Step 1b: fetchingPhoto');
    yield const DataInitProgress(DataInitStatus.fetchingPhoto);
    final photoBytes = await _fetchPhotoBestEffort(
      npm: npm,
      password: password,
    );
    final bool photoEagerCachedLight =
        photoBytes != null && photoBytes.isNotEmpty;
    if (photoBytes == null || photoBytes.isEmpty) {
      yield const DataInitProgress(DataInitStatus.photoEmpty);
    } else {
      await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
    }

    // 3. Blok KRS ringan: langsung get data, skip download/extract (opsional)
    try {
      debugPrint('[DATA_INIT_DS] Light Step 4: fetchingKrsData');
      yield const DataInitProgress(DataInitStatus.fetchingKrsData);
      final isKrsEmpty = await _fetchKrsDataOrEmpty(
        npm: npm,
        forceRefresh: true,
      );
      if (isKrsEmpty) {
        yield const DataInitProgress(DataInitStatus.krsEmpty);
      }
    } catch (e) {
      if (isNetworkError(e)) rethrow;
      // KRS fetch failure is non-fatal — yield empty status
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'krs',
          result: DataInitStepResult.error,
          message: e.toString(),
        ),
      );
      debugPrint('[DATA_INIT_DS] KRS fetch failed (non-fatal): $e');
      yield const DataInitProgress(DataInitStatus.krsEmpty);
    }

    // 4. Blok KHS ringan: semesters + get data per semester,
    //    skip download/extract (opsional)
    try {
      debugPrint('[DATA_INIT_DS] Light Step 5: fetchingKhsSemesters');
      yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
      final semesters = await _fetchKhsSemesters(npm: npm, password: password);

      debugPrint(
        '[DATA_INIT_DS] Light: Processing ${semesters.length} KHS semesters (data only)',
      );
      final List<String> khsErrors = [];
      for (final semesterEntry in semesters) {
        final detail = '${semesterEntry.tahunAjaran} ${semesterEntry.semester}';
        debugPrint('[DATA_INIT_DS] Light KHS semester: $detail');
        try {
          // Langsung get data — tanpa download/extract.
          yield DataInitProgress(
            DataInitStatus.fetchingKhsData,
            detail: detail,
          );
          await _fetchKhsDataForSemester(
            npm: npm,
            tahunAjaran: semesterEntry.tahunAjaran,
            semester: semesterEntry.semester,
            forceRefresh: true,
          );
        } catch (e) {
          if (isNetworkError(e)) rethrow;
          yield DataInitProgress(
            DataInitStatus.fetchingKhsData,
            detail: '$detail ::error::fetch',
          );
          khsErrors.add('Gagal memuat KHS ${semesterEntry.semester}: $e');
          _logStepOutcome(
            DataInitStepOutcome(
              step: 'khs_$detail',
              result: DataInitStepResult.error,
              message: e.toString(),
            ),
          );
          // Continue to next semester — don't stop pipeline
        }
      }

      if (khsErrors.isNotEmpty) {
        debugPrint(
          '[DATA_INIT_DS] Light KHS completed with ${khsErrors.length} errors',
        );
        yield const DataInitProgress(DataInitStatus.khsEmpty);
      }
    } catch (e) {
      if (isNetworkError(e)) rethrow;
      // KHS fetch failure is non-fatal — yield empty status
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'khs',
          result: DataInitStepResult.error,
          message: e.toString(),
        ),
      );
      debugPrint('[DATA_INIT_DS] KHS fetch failed (non-fatal): $e');
      yield const DataInitProgress(DataInitStatus.khsEmpty);
    }

    // 5. Cache foto di akhir — skip jika sudah eager
    if (!photoEagerCachedLight) {
      await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
    }

    // 6. SELESAI
    debugPrint('[DATA_INIT_DS] Light pipeline completed');
    yield const DataInitProgress(DataInitStatus.completed);
  }

  /// Step 1 bersama: getProfile wajib — gagal = rethrow, pipeline berhenti.
  /// [AppException] (termasuk AuthException/401) merethrow apa adanya,
  /// bukan ditelan sebagai empty — sama seperti jalur berat.
  Future<void> _fetchProfileOrThrow({
    required String npm,
    required String password,
    required bool forceRefresh,
  }) async {
    try {
      await _runStep(
        'profile_get',
        () => _profileDataSource.getProfile(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        ),
      );
      _logStepOutcome(
        const DataInitStepOutcome(
          step: 'profile_get',
          result: DataInitStepResult.success,
        ),
      );
    } catch (e) {
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'profile_get',
          result: DataInitStepResult.error,
          message: e.toString(),
        ),
      );
      rethrow; // Profile is mandatory — rethrow to stop pipeline
    }
  }

  /// Step 1b bersama: fetchPhoto non-fatal — gagal/kosong = null.
  /// Caller yield [DataInitStatus.photoEmpty] bila hasilnya null/kosong.
  Future<Uint8List?> _fetchPhotoBestEffort({
    required String npm,
    required String password,
  }) async {
    try {
      final photoBytes = await _photoService.fetchPhoto(
        npm: npm,
        password: password,
      );
      if (photoBytes == null || photoBytes.isEmpty) {
        _logStepOutcome(
          const DataInitStepOutcome(
            step: 'fetch_photo',
            result: DataInitStepResult.empty,
            message: 'Foto kosong',
          ),
        );
        return null;
      }
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'fetch_photo',
          result: DataInitStepResult.success,
          message: '${photoBytes.length} bytes',
        ),
      );
      return photoBytes;
    } catch (e) {
      // Photo fetch failure is non-fatal — don't stop pipeline
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'fetch_photo',
          result: DataInitStepResult.error,
          message: e.toString(),
        ),
      );
      return null;
    }
  }

  /// Step 4 bersama: getKrsData — return true bila mata kuliah kosong
  /// (caller yield [DataInitStatus.krsEmpty]).
  Future<bool> _fetchKrsDataOrEmpty({
    required String npm,
    required bool forceRefresh,
  }) async {
    final krsData = await _runStep(
      'krs_data',
      () => _getKrs(npm: npm, forceRefresh: forceRefresh),
    );
    if (krsData.krs.mataKuliah.isEmpty) {
      _logStepOutcome(
        const DataInitStepOutcome(
          step: 'krs_data',
          result: DataInitStepResult.empty,
          message: 'Mata kuliah kosong',
        ),
      );
      return true;
    }
    _logStepOutcome(
      DataInitStepOutcome(
        step: 'krs_data',
        result: DataInitStepResult.success,
        message: '${krsData.krs.mataKuliah.length} mata kuliah',
      ),
    );
    return false;
  }

  /// Step 5 bersama: getSemesters (selalu fresh).
  Future<List<KhsSemesterEntity>> _fetchKhsSemesters({
    required String npm,
    required String password,
  }) async {
    final semesters = await _runStep(
      'khs_semesters',
      () => _getKhs.getSemesters(npm: npm, password: password),
    );
    _logStepOutcome(
      DataInitStepOutcome(
        step: 'khs_semesters',
        result: semesters.isEmpty
            ? DataInitStepResult.empty
            : DataInitStepResult.success,
        message: '${semesters.length} semester',
      ),
    );
    return semesters;
  }

  /// Step 8 bersama: getKhsData satu semester (tanpa download/extract).
  /// failedStep memakai nama semester saja (`khs_data_Ganjil`).
  Future<void> _fetchKhsDataForSemester({
    required String npm,
    required String tahunAjaran,
    required String semester,
    required bool forceRefresh,
  }) async {
    await _runStep(
      'khs_data_$semester',
      () => _getKhs(
        npm: npm,
        tahunAjaran: tahunAjaran,
        semester: semester,
        forceRefresh: forceRefresh,
      ),
    );
    _logStepOutcome(
      DataInitStepOutcome(
        step: 'khs_data_$tahunAjaran $semester',
        result: DataInitStepResult.success,
      ),
    );
  }

  /// Tail bersama: cache foto bila ada — identik di kedua cabang.
  Future<void> _cachePhotoIfPresent({
    required String npm,
    Uint8List? photoBytes,
  }) async {
    if (photoBytes != null && photoBytes.isNotEmpty) {
      await _avatarCache.saveAvatar(npm: npm, bytes: photoBytes);
      _avatarCubit.onPhotoCached(npm, photoBytes);
      debugPrint('[DataInitDS] Photo cached: ${photoBytes.length} bytes');
    }
  }

  // Helpers to avoid duplicating heavy logic inside resumeFrom
  Future<void> _phaseScrapeAndProfile({
    required String npm,
    required String password,
    required bool forceRefresh,
  }) async {
    await _runStep(
      'profile_scrape_1',
      () => _profileDataSource.scrapeProfile(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
      ),
    );
    await _runStep(
      'profile_scrape_2',
      () => _profileDataSource.scrapeProfile(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
      ),
    );
    await _fetchProfileOrThrow(
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
    );
  }

  Stream<DataInitProgress> _phaseKhsSemestersAndLoop({
    required String npm,
    required String password,
    required bool forceRefresh,
    int startIndex = 0,
    List<KhsSemesterEntity>? preFetchedSemesters,
  }) async* {
    final semesters =
        preFetchedSemesters ??
        await _fetchKhsSemesters(npm: npm, password: password);
    final List<String> khsErrors = [];
    for (var i = startIndex; i < semesters.length; i++) {
      final semesterEntry = semesters[i];
      final detail = '${semesterEntry.tahunAjaran} ${semesterEntry.semester}';
      try {
        yield* _khsSemesterSteps(
          detail: detail,
          semesterEntry: semesterEntry,
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        if (isNetworkError(e)) rethrow;
        final stepName = e is DataInitStepException ? e.step : '';
        final failSub = stepName.startsWith('khs_extract')
            ? 'extract'
            : stepName.startsWith('khs_download')
            ? 'download'
            : 'fetch';
        khsErrors.add('Gagal memuat KHS ${semesterEntry.semester}: $e');
        _logStepOutcome(
          DataInitStepOutcome(
            step: 'khs_$detail',
            result: DataInitStepResult.error,
            message: e.toString(),
          ),
        );
        yield DataInitProgress(
          DataInitStatus.fetchingKhsData,
          detail: '$detail ::error::$failSub',
        );
      }
    }
    if (khsErrors.isNotEmpty) {
      yield const DataInitProgress(DataInitStatus.khsEmpty);
    }
  }

  Stream<DataInitProgress> _khsSemesterSteps({
    required String detail,
    required KhsSemesterEntity semesterEntry,
    required String npm,
    required String password,
    required bool forceRefresh,
  }) async* {
    yield DataInitProgress(DataInitStatus.downloadingKhs, detail: detail);
    await _runStep(
      'khs_download_${semesterEntry.semester}',
      () => _getKhs.download(
        npm: npm,
        password: password,
        tahunAjaran: semesterEntry.tahunAjaran,
        semester: semesterEntry.semester,
        forceRefresh: forceRefresh,
      ),
    );
    yield DataInitProgress(DataInitStatus.extractingKhs, detail: detail);
    await _runStep(
      'khs_extract_${semesterEntry.semester}',
      () => _getKhs.extract(
        npm: npm,
        password: password,
        tahunAjaran: semesterEntry.tahunAjaran,
        semester: semesterEntry.semester,
        forceRefresh: forceRefresh,
      ),
    );
    yield DataInitProgress(DataInitStatus.fetchingKhsData, detail: detail);
    await _fetchKhsDataForSemester(
      npm: npm,
      tahunAjaran: semesterEntry.tahunAjaran,
      semester: semesterEntry.semester,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _phaseKrs({
    required String npm,
    required String password,
    required bool forceRefresh,
    String startAt = 'download',
  }) async {
    if (startAt == 'download') {
      await _runStep(
        'krs_download',
        () => _getKrs.download(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        ),
      );
      _logStepOutcome(
        const DataInitStepOutcome(
          step: 'krs_download',
          result: DataInitStepResult.success,
        ),
      );
      startAt = 'extract';
    }
    if (startAt == 'extract') {
      await _runStep(
        'krs_extract',
        () => _getKrs.extract(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        ),
      );
      _logStepOutcome(
        const DataInitStepOutcome(
          step: 'krs_extract',
          result: DataInitStepResult.success,
        ),
      );
      startAt = 'data';
    }
    if (startAt == 'data') {
      final isKrsEmpty = await _fetchKrsDataOrEmpty(
        npm: npm,
        forceRefresh: forceRefresh,
      );
      if (isKrsEmpty) {
        // caller handles krsEmpty emit
      }
    }
  }

  /// M2 granular resume — continues from [failedStep] onward.
  /// Profile already cached before KRS/KHS, so KRS/KHS resume safely skips it.
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  }) async* {
    debugPrint('[DATA_INIT_DS] resumeFrom $failedStep — START');
    Uint8List? photoBytes = cachedPhotoBytes;

    // Phase gates
    final isKrs = failedStep.startsWith('krs');
    final isKhs = failedStep.startsWith('khs');

    if (!isKrs && !isKhs) {
      // Profile/timeout/unknown → full restart via phase helpers
      debugPrint('[DATA_INIT_DS] resumeFrom → full restart (profile phase)');
      yield const DataInitProgress(DataInitStatus.scrapingProfile);
      await _phaseScrapeAndProfile(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
      );
      yield const DataInitProgress(DataInitStatus.gettingProfile);
      yield const DataInitProgress(DataInitStatus.fetchingPhoto);
      photoBytes = await _fetchPhotoBestEffort(npm: npm, password: password);
      if (photoBytes == null || photoBytes.isEmpty) {
        yield const DataInitProgress(DataInitStatus.photoEmpty);
      }
      // Fall through to KRS then KHS
      try {
        yield const DataInitProgress(DataInitStatus.downloadingKrs);
        await _phaseKrs(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        if (isNetworkError(e)) rethrow;
        yield const DataInitProgress(DataInitStatus.krsEmpty);
      }
      try {
        yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
        await for (final p in _phaseKhsSemestersAndLoop(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        )) {
          yield p;
        }
      } catch (e) {
        if (isNetworkError(e)) rethrow;
        yield const DataInitProgress(DataInitStatus.khsEmpty);
      }
      await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
      yield const DataInitProgress(DataInitStatus.completed);
      return;
    }

    // KRS resume — profile already cached, skip it
    if (isKrs) {
      final start = failedStep == 'krs_extract'
          ? 'extract'
          : failedStep == 'krs_data'
          ? 'data'
          : 'download';
      final status = start == 'extract'
          ? DataInitStatus.extractingKrs
          : start == 'data'
          ? DataInitStatus.fetchingKrsData
          : DataInitStatus.downloadingKrs;
      yield DataInitProgress(status);
      try {
        await _phaseKrs(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
          startAt: start,
        );
      } catch (e) {
        if (isNetworkError(e)) rethrow;
        yield const DataInitProgress(DataInitStatus.krsEmpty);
      }
      // Continue KHS fully
      try {
        yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
        await for (final p in _phaseKhsSemestersAndLoop(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        )) {
          yield p;
        }
      } catch (e) {
        if (isNetworkError(e)) rethrow;
        yield const DataInitProgress(DataInitStatus.khsEmpty);
      }
      await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
      yield const DataInitProgress(DataInitStatus.completed);
      return;
    }

    // KHS resume — need semesters; locate failed semester index
    if (failedStep == 'khs_semesters') {
      try {
        yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
        await for (final p in _phaseKhsSemestersAndLoop(
          npm: npm,
          password: password,
          forceRefresh: forceRefresh,
        )) {
          yield p;
        }
      } catch (e) {
        if (isNetworkError(e)) rethrow;
        yield const DataInitProgress(DataInitStatus.khsEmpty);
      }
      await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
      yield const DataInitProgress(DataInitStatus.completed);
      return;
    }

    // khs_{download,extract,data}_<Semester>
    final semester = failedStep.split('_').last;
    final semesters = await _fetchKhsSemesters(npm: npm, password: password);
    var idx = semesters.indexWhere((s) => s.semester == semester);
    if (idx < 0) idx = 0;
    final failed = semesters[idx];
    final detail = '${failed.tahunAjaran} ${failed.semester}';
    final sub = failedStep.startsWith('khs_extract')
        ? 'extract'
        : failedStep.startsWith('khs_data')
        ? 'data'
        : 'download';
    if (sub == 'download') {
      yield DataInitProgress(DataInitStatus.downloadingKhs, detail: detail);
      await _runStep(
        'khs_download_${failed.semester}',
        () => _getKhs.download(
          npm: npm,
          password: password,
          tahunAjaran: failed.tahunAjaran,
          semester: failed.semester,
          forceRefresh: forceRefresh,
        ),
      );
      yield DataInitProgress(DataInitStatus.extractingKhs, detail: detail);
      await _runStep(
        'khs_extract_${failed.semester}',
        () => _getKhs.extract(
          npm: npm,
          password: password,
          tahunAjaran: failed.tahunAjaran,
          semester: failed.semester,
          forceRefresh: forceRefresh,
        ),
      );
      yield DataInitProgress(DataInitStatus.fetchingKhsData, detail: detail);
      await _fetchKhsDataForSemester(
        npm: npm,
        tahunAjaran: failed.tahunAjaran,
        semester: failed.semester,
        forceRefresh: forceRefresh,
      );
    } else if (sub == 'extract') {
      yield DataInitProgress(DataInitStatus.extractingKhs, detail: detail);
      await _runStep(
        'khs_extract_${failed.semester}',
        () => _getKhs.extract(
          npm: npm,
          password: password,
          tahunAjaran: failed.tahunAjaran,
          semester: failed.semester,
          forceRefresh: forceRefresh,
        ),
      );
      yield DataInitProgress(DataInitStatus.fetchingKhsData, detail: detail);
      await _fetchKhsDataForSemester(
        npm: npm,
        tahunAjaran: failed.tahunAjaran,
        semester: failed.semester,
        forceRefresh: forceRefresh,
      );
    } else {
      yield DataInitProgress(DataInitStatus.fetchingKhsData, detail: detail);
      await _fetchKhsDataForSemester(
        npm: npm,
        tahunAjaran: failed.tahunAjaran,
        semester: failed.semester,
        forceRefresh: forceRefresh,
      );
    }
    // Remaining semesters
    if (idx + 1 < semesters.length) {
      await for (final p in _phaseKhsSemestersAndLoop(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
        startIndex: idx + 1,
        preFetchedSemesters: semesters,
      )) {
        yield p;
      }
    }
    await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);
    yield const DataInitProgress(DataInitStatus.completed);
  }

  /// Wraps [fn] in a try/catch, converting errors into [DataInitStepException].
  /// Preserves the original [AppException] as [originalError] so
  /// [isNetworkError] can classify network failures while keeping the step.
  Future<T> _runStep<T>(String step, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      if (e is DataInitStepException) rethrow;
      if (e is AppException) {
        throw DataInitStepException(step, e.message, e);
      }
      throw DataInitStepException(step, e.toString(), e);
    }
  }

  /// Logs pipeline step outcome using [DataInitStepOutcome] for debugging.
  void _logStepOutcome(DataInitStepOutcome outcome) {
    final statusIcon = switch (outcome.result) {
      DataInitStepResult.success => '✅',
      DataInitStepResult.empty => '⚠️',
      DataInitStepResult.error => '❌',
    };
    debugPrint(
      '[DataInitDS] Step: ${outcome.step} → $statusIcon ${outcome.result.name}'
      '${outcome.message != null ? ' (${outcome.message})' : ''}',
    );
  }
}
