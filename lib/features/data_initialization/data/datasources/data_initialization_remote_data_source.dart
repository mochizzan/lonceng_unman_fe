import 'dart:async';

import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/khs_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';

/// Orchestrates the post-login data initialization pipeline.
///
/// Pipeline (8 steps on home page):
///   0. Clear cache         → clear KRS + KHS (keeps credentials)
///   KRS:
///   1. Download KRS PDF  → POST /api/v1/lms/krs
///   2. Extract KRS       → POST /api/v1/lms/krs/extract
///   3. Fetch KRS data    → POST /api/v1/lms/krs/data
///   KHS:
///   4. Get KHS semesters → POST /api/v1/lms/khs/semesters
///   5. Download KHS PDF  → POST /api/v1/lms/khs
///   6. Extract KHS       → POST /api/v1/lms/khs/extract
///   7. Fetch KHS data    → POST /api/v1/lms/khs/data
///
/// Login (1 call on login page):
///   POST /api/v1/lms/login
///
/// Total: 8 endpoint hits + 1 cache clear.
class DataInitializationRemoteDataSource {
  final GetKrs _getKrs;
  final GetKhs _getKhs;
  final AcademicCacheService _academicCacheService;
  final KhsCacheService _khsCacheService;

  DataInitializationRemoteDataSource({
    required GetKrs getKrs,
    required GetKhs getKhs,
    required AcademicCacheService academicCacheService,
    KhsCacheService? khsCacheService,
  }) : _getKrs = getKrs,
       _getKhs = getKhs,
       _academicCacheService = academicCacheService,
       _khsCacheService = khsCacheService ?? KhsCacheService();

  Stream<DataInitStatus> initialize({
    required String npm,
    required String password,
  }) async* {
    // Step 0: Clear cache
    yield DataInitStatus.clearingCache;
    await _academicCacheService.clearAcademicData();
    await _khsCacheService.clearAll(npm: npm);

    // ── KRS ──

    // Step 1: Download KRS PDF
    yield DataInitStatus.downloadingKrs;
    await _runStep(
      'krs_download',
      () => _getKrs.download(npm: npm, password: password),
    );

    // Step 2: Extract KRS
    yield DataInitStatus.extractingKrs;
    await _runStep(
      'krs_extract',
      () => _getKrs.extract(npm: npm, password: password),
    );

    // Step 3: Fetch KRS data
    yield DataInitStatus.fetchingKrsData;
    final krsData = await _runStep('krs_data', () => _getKrs(npm: npm));
    if (krsData.krs.mataKuliah.isEmpty) {
      throw const DataInitStepException('krs_data', 'Data KRS kosong');
    }

    // ── KHS ──

    // Step 4: Get available KHS semesters
    yield DataInitStatus.fetchingKhsSemesters;
    final semesters = await _runStep(
      'khs_semesters',
      () => _getKhs.getSemesters(npm: npm, password: password),
    );

    // Steps 5-7: Process the previous semester's KHS (if available)
    if (semesters.length >= 2) {
      final previous = semesters[semesters.length - 2];

      // Step 5: Download KHS PDF
      yield DataInitStatus.downloadingKhs;
      await _runStep(
        'khs_download',
        () => _getKhs.download(
          npm: npm,
          password: password,
          tahunAjaran: previous.tahunAjaran,
          semester: previous.semester,
        ),
      );

      // Step 6: Extract KHS
      yield DataInitStatus.extractingKhs;
      await _runStep(
        'khs_extract',
        () => _getKhs.extract(
          npm: npm,
          password: password,
          tahunAjaran: previous.tahunAjaran,
          semester: previous.semester,
        ),
      );

      // Step 7: Fetch KHS data
      yield DataInitStatus.fetchingKhsData;
      await _runStep(
        'khs_data',
        () => _getKhs(
          npm: npm,
          tahunAjaran: previous.tahunAjaran,
          semester: previous.semester,
        ),
      );
    }

    yield DataInitStatus.completed;
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
