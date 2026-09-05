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

  /// Jalur berat: pipeline penuh (pindahan body initialize() sebelumnya,
  /// logika/urutan/nama step tidak berubah).
  Stream<DataInitProgress> _initializeHeavy({
    required String npm,
    required String password,
    required bool forceRefresh,
  }) async* {
    debugPrint(
      '[DATA_INIT_DS] _initializeHeavy() START — npm=$npm, forceRefresh=$forceRefresh',
    );

    // ═══════════════════════════════════════════════════════════════
    // PHASE 1: FETCH ALL — profil wajib, sisanya opsional
    // ═══════════════════════════════════════════════════════════════

    // ── Profile (WAJIB — gagal = pipeline berhenti) ──

    // Step 0a: Scrape Profile (first attempt)
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

    // Step 0b: Scrape Profile (second attempt for reliability)
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

    // Step 1: Get Profile — juga meng-cache secara internal
    debugPrint('[DATA_INIT_DS] Step 1: gettingProfile');
    yield const DataInitProgress(DataInitStatus.gettingProfile);
    await _fetchProfileOrThrow(
      npm: npm,
      password: password,
      forceRefresh: forceRefresh,
    );

    // ── Foto Profil (opsional) ──

    // Step 1b: Fetch photo from LMS
    debugPrint('[DATA_INIT_DS] Step 1b: fetchingPhoto');
    yield const DataInitProgress(DataInitStatus.fetchingPhoto);
    final photoBytes = await _fetchPhotoBestEffort(
      npm: npm,
      password: password,
    );
    if (photoBytes == null || photoBytes.isEmpty) {
      yield const DataInitProgress(DataInitStatus.photoEmpty);
    }

    // ── KRS (opsional) ──

    try {
      // Step 2: Download KRS PDF
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

      // Step 3: Extract KRS
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

      // Step 4: Fetch KRS data (cache internally by data source)
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

    // ── KHS (opsional) ──

    try {
      // Step 5: Get available KHS semesters
      debugPrint('[DATA_INIT_DS] Step 5: fetchingKhsSemesters');
      yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
      final semesters = await _fetchKhsSemesters(npm: npm, password: password);

      // Steps 6-8: Process ALL available KHS semesters
      debugPrint(
        '[DATA_INIT_DS] Steps 6-8: Processing ${semesters.length} KHS semesters',
      );
      final List<String> khsErrors = [];
      for (final semesterEntry in semesters) {
        final detail = '${semesterEntry.tahunAjaran} ${semesterEntry.semester}';
        debugPrint('[DATA_INIT_DS] KHS semester: $detail');
        try {
          // Step 6: Download KHS PDF
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
          _logStepOutcome(
            DataInitStepOutcome(
              step: 'khs_download_$detail',
              result: DataInitStepResult.success,
            ),
          );

          // Step 7: Extract KHS
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
          _logStepOutcome(
            DataInitStepOutcome(
              step: 'khs_extract_$detail',
              result: DataInitStepResult.success,
            ),
          );

          // Step 8: Fetch KHS data (cache internally by data source)
          yield DataInitProgress(
            DataInitStatus.fetchingKhsData,
            detail: detail,
          );
          await _fetchKhsDataForSemester(
            npm: npm,
            tahunAjaran: semesterEntry.tahunAjaran,
            semester: semesterEntry.semester,
            forceRefresh: forceRefresh,
          );
        } catch (e) {
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
          '[DATA_INIT_DS] KHS completed with ${khsErrors.length} errors',
        );
        yield const DataInitProgress(DataInitStatus.khsEmpty);
      }
    } catch (e) {
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

    // ═══════════════════════════════════════════════════════════════
    // PHASE 2: CACHE FOTO — cache hanya foto di akhir pipeline
    // ═══════════════════════════════════════════════════════════════

    // KRS dan KHS sudah di-cache oleh data source masing-masing secara internal.
    await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);

    // ═══════════════════════════════════════════════════════════════
    // SELESAI
    // ═══════════════════════════════════════════════════════════════

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
    if (photoBytes == null || photoBytes.isEmpty) {
      yield const DataInitProgress(DataInitStatus.photoEmpty);
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

    // 5. Cache foto di akhir — identik jalur berat.
    await _cachePhotoIfPresent(npm: npm, photoBytes: photoBytes);

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
      unawaited(_avatarCubit.bindNpm(npm));
      debugPrint('[DataInitDS] Photo cached: ${photoBytes.length} bytes');
    }
  }

  /// Wraps [fn] in a try/catch, converting errors into [DataInitStepException].
  Future<T> _runStep<T>(String step, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      // Preserve original exception type if it's already an AppException
      if (e is AppException) rethrow;
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
