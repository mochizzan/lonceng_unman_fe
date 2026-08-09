import 'dart:async';
import 'dart:developer' as developer;

import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';

/// Orchestrates the post-login data initialization pipeline.
///
/// Non-destructive: new data overwrites old cache entries directly.
/// Pipeline (home page):
///   Profile:
///   0. Scrape Profile (2x) → POST /api/v1/lms/student-profile
///   1. Get Profile         → POST /api/v1/lms/student-profile/data
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

  DataInitializationRemoteDataSource({
    required GetKrs getKrs,
    required GetKhs getKhs,
    required StudentProfileRemoteDataSource profileDataSource,
  }) : _getKrs = getKrs,
       _getKhs = getKhs,
       _profileDataSource = profileDataSource;

  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
  }) async* {
    // ── Profile ──

    // Step 0a: Scrape Profile (first attempt)
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    await _runStep(
      'profile_scrape_1',
      () => _profileDataSource.scrapeProfile(npm: npm, password: password),
    );

    // Step 0b: Scrape Profile (second attempt for reliability)
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    await _runStep(
      'profile_scrape_2',
      () => _profileDataSource.scrapeProfile(npm: npm, password: password),
    );

    // Step 1: Get Profile
    yield const DataInitProgress(DataInitStatus.gettingProfile);
    await _runStep(
      'profile_get',
      () => _profileDataSource.getProfile(npm: npm, password: password),
    );

    // ── KRS ──

    // Step 2: Download KRS PDF
    yield const DataInitProgress(DataInitStatus.downloadingKrs);
    await _runStep(
      'krs_download',
      () => _getKrs.download(npm: npm, password: password),
    );

    // Step 3: Extract KRS
    yield const DataInitProgress(DataInitStatus.extractingKrs);
    await _runStep(
      'krs_extract',
      () => _getKrs.extract(npm: npm, password: password),
    );

    // Step 4: Fetch KRS data
    yield const DataInitProgress(DataInitStatus.fetchingKrsData);
    final krsData = await _runStep('krs_data', () => _getKrs(npm: npm));
    if (krsData.krs.mataKuliah.isEmpty) {
      throw const DataInitStepException('krs_data', 'Data KRS kosong');
    }

    // ── KHS ──

    // Step 5: Get available KHS semesters
    yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
    final semesters = await _runStep(
      'khs_semesters',
      () => _getKhs.getSemesters(npm: npm, password: password),
    );

    // Steps 6-8: Process ALL available KHS semesters
    final List<String> khsErrors = [];
    for (final semesterEntry in semesters) {
      final detail = '${semesterEntry.tahunAjaran} ${semesterEntry.semester}';
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
      developer.log(
        'Data init completed with errors: ${khsErrors.join(', ')}',
        name: 'DataInitDS',
      );
      yield const DataInitProgress(DataInitStatus.completedWithErrors);
    } else {
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
