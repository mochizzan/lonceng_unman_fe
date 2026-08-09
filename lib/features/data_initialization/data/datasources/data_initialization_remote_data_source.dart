import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
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

  DataInitializationRemoteDataSource({
    required GetKrs getKrs,
    required GetKhs getKhs,
    required StudentProfileRemoteDataSource profileDataSource,
    PhotoService? photoService,
    AvatarCacheService? avatarCache,
  }) : _getKrs = getKrs,
       _getKhs = getKhs,
       _profileDataSource = profileDataSource,
       _photoService = photoService ?? Services.get<PhotoService>(),
       _avatarCache = avatarCache ?? Services.get<AvatarCacheService>();

  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
  }) async* {
    debugPrint(
      '[DATA_INIT_DS] initialize() START — npm=$npm, forceRefresh=$forceRefresh',
    );
    // ── Profile ──

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

    // Step 1: Get Profile
    debugPrint('[DATA_INIT_DS] Step 1: gettingProfile');
    yield const DataInitProgress(DataInitStatus.gettingProfile);
    await _runStep(
      'profile_get',
      () => _profileDataSource.getProfile(
        npm: npm,
        password: password,
        forceRefresh: forceRefresh,
      ),
    );

    // ── Foto Profil ──

    // Step 1b: Fetch photo from LMS
    debugPrint('[DATA_INIT_DS] Step 1b: fetchingPhoto');
    yield const DataInitProgress(DataInitStatus.fetchingPhoto);
    try {
      final photoBytes = await _photoService.fetchPhoto(
        npm: npm,
        password: password,
      );
      if (photoBytes != null && photoBytes.isNotEmpty) {
        await _avatarCache.saveAvatar(npm: npm, bytes: photoBytes);
        developer.log(
          'Photo saved to cache: ${photoBytes.length} bytes',
          name: 'DataInitDS',
        );
      }
    } catch (e) {
      // Photo fetch failure is non-fatal — don't stop pipeline
      developer.log('Photo fetch failed (non-fatal): $e', name: 'DataInitDS');
    }

    // ── KRS ──

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

    // Step 4: Fetch KRS data
    debugPrint('[DATA_INIT_DS] Step 4: fetchingKrsData');
    yield const DataInitProgress(DataInitStatus.fetchingKrsData);
    final krsData = await _runStep(
      'krs_data',
      () => _getKrs(npm: npm, forceRefresh: forceRefresh),
    );
    if (krsData.krs.mataKuliah.isEmpty) {
      throw const DataInitStepException('krs_data', 'Data KRS kosong');
    }

    // ── KHS ──

    // Step 5: Get available KHS semesters
    debugPrint('[DATA_INIT_DS] Step 5: fetchingKhsSemesters');
    yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
    final semesters = await _runStep(
      'khs_semesters',
      () => _getKhs.getSemesters(npm: npm, password: password),
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

        // Step 8: Fetch KHS data
        yield DataInitProgress(DataInitStatus.fetchingKhsData, detail: detail);
        await _runStep(
          'khs_data_${semesterEntry.semester}',
          () => _getKhs(
            npm: npm,
            tahunAjaran: semesterEntry.tahunAjaran,
            semester: semesterEntry.semester,
            forceRefresh: forceRefresh,
          ),
        );
      } catch (e) {
        khsErrors.add('Gagal memuat KHS ${semesterEntry.semester}: $e');
        developer.log(
          'KHS semester ${semesterEntry.semester} failed: $e',
          name: 'DataInitDS',
        );
        // Continue to next semester — don't stop pipeline
      }
    }

    if (khsErrors.isNotEmpty) {
      debugPrint(
        '[DATA_INIT_DS] Pipeline completed with ${khsErrors.length} errors',
      );
      developer.log(
        'Data init completed with errors: ${khsErrors.join(', ')}',
        name: 'DataInitDS',
      );
      yield const DataInitProgress(DataInitStatus.completedWithErrors);
    } else {
      debugPrint('[DATA_INIT_DS] Pipeline completed SUCCESSFULLY');
      yield const DataInitProgress(DataInitStatus.completed);
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
}
