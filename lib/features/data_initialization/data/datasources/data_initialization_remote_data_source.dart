import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';

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
class DataInitializationRemoteDataSource {
  final GetKrs _getKrs;
  final GetKhs _getKhs;
  final StudentProfileRemoteDataSource _profileDataSource;
  final PhotoService _photoService;
  final AvatarCacheService _avatarCache;
  final AvatarCubit _avatarCubit;

  DataInitializationRemoteDataSource({
    required GetKrs getKrs,
    required GetKhs getKhs,
    required StudentProfileRemoteDataSource profileDataSource,
    PhotoService? photoService,
    AvatarCacheService? avatarCache,
    AvatarCubit? avatarCubit,
  }) : _getKrs = getKrs,
       _getKhs = getKhs,
       _profileDataSource = profileDataSource,
       _photoService = photoService ?? Services.get<PhotoService>(),
       _avatarCache = avatarCache ?? Services.get<AvatarCacheService>(),
       _avatarCubit = avatarCubit ?? Services.get<AvatarCubit>();

  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
  }) async* {
    debugPrint(
      '[DATA_INIT_DS] initialize() START — npm=$npm, forceRefresh=$forceRefresh',
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

    // ── Foto Profil (opsional) ──

    // Step 1b: Fetch photo from LMS
    debugPrint('[DATA_INIT_DS] Step 1b: fetchingPhoto');
    yield const DataInitProgress(DataInitStatus.fetchingPhoto);
    Uint8List? photoBytes;
    try {
      photoBytes = await _photoService.fetchPhoto(npm: npm, password: password);
      if (photoBytes == null || photoBytes.isEmpty) {
        _logStepOutcome(
          const DataInitStepOutcome(
            step: 'fetch_photo',
            result: DataInitStepResult.empty,
            message: 'Foto kosong',
          ),
        );
        yield const DataInitProgress(DataInitStatus.photoEmpty);
      } else {
        _logStepOutcome(
          DataInitStepOutcome(
            step: 'fetch_photo',
            result: DataInitStepResult.success,
            message: '${photoBytes.length} bytes',
          ),
        );
      }
    } catch (e) {
      // Photo fetch failure is non-fatal — don't stop pipeline
      _logStepOutcome(
        DataInitStepOutcome(
          step: 'fetch_photo',
          result: DataInitStepResult.error,
          message: e.toString(),
        ),
      );
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
        yield const DataInitProgress(DataInitStatus.krsEmpty);
      } else {
        _logStepOutcome(
          DataInitStepOutcome(
            step: 'krs_data',
            result: DataInitStepResult.success,
            message: '${krsData.krs.mataKuliah.length} mata kuliah',
          ),
        );
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
          await _runStep(
            'khs_data_${semesterEntry.semester}',
            () => _getKhs(
              npm: npm,
              tahunAjaran: semesterEntry.tahunAjaran,
              semester: semesterEntry.semester,
              forceRefresh: forceRefresh,
            ),
          );
          _logStepOutcome(
            DataInitStepOutcome(
              step: 'khs_data_$detail',
              result: DataInitStepResult.success,
            ),
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
    // Cache foto — dipindah dari dalam try/catch ke sini
    if (photoBytes != null && photoBytes.isNotEmpty) {
      await _avatarCache.saveAvatar(npm: npm, bytes: photoBytes);
      unawaited(_avatarCubit.bindNpm(npm));
      debugPrint('[DataInitDS] Photo cached: ${photoBytes.length} bytes');
    }

    // ═══════════════════════════════════════════════════════════════
    // SELESAI
    // ═══════════════════════════════════════════════════════════════

    debugPrint('[DATA_INIT_DS] Pipeline completed');
    yield const DataInitProgress(DataInitStatus.completed);
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
