import 'dart:async';
import 'dart:developer' as developer;

import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';

/// Orchestrates the post-login data initialization pipeline.
///
/// Non-destructive: new data overwrites old cache entries directly.
/// Pipeline (home page):
///   KRS:
///   1. Download KRS PDF   → POST /api/v1/lms/krs
///   2. Extract KRS        → POST /api/v1/lms/krs/extract
///   3. Fetch KRS data     → POST /api/v1/lms/krs/data
///   KHS:
///   4. Get KHS semesters  → POST /api/v1/lms/khs/semesters
///   5. Download KHS PDF   → POST /api/v1/lms/khs
///   6. Extract KHS        → POST /api/v1/lms/khs/extract
///   7. Fetch KHS data     → POST /api/v1/lms/khs/data
///
/// Login (1 call on login page):
///   POST /api/v1/lms/login
///
/// Total: 8 endpoint hits.
class DataInitializationRemoteDataSource {
  final GetKrs _getKrs;
  final GetKhs _getKhs;

  DataInitializationRemoteDataSource({
    required GetKrs getKrs,
    required GetKhs getKhs,
  }) : _getKrs = getKrs,
       _getKhs = getKhs;

  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
  }) async* {
    // ── KRS ──

    // Step 1: Download KRS PDF
    yield const DataInitProgress(DataInitStatus.downloadingKrs);
    await _runStep(
      'krs_download',
      () => _getKrs.download(npm: npm, password: password),
    );

    // Step 2: Extract KRS
    yield const DataInitProgress(DataInitStatus.extractingKrs);
    await _runStep(
      'krs_extract',
      () => _getKrs.extract(npm: npm, password: password),
    );

    // Step 3: Fetch KRS data
    yield const DataInitProgress(DataInitStatus.fetchingKrsData);
    final krsData = await _runStep('krs_data', () => _getKrs(npm: npm));
    if (krsData.krs.mataKuliah.isEmpty) {
      throw const DataInitStepException('krs_data', 'Data KRS kosong');
    }

    // ── KHS ──

    // Step 4: Get available KHS semesters
    yield const DataInitProgress(DataInitStatus.fetchingKhsSemesters);
    final semesters = await _runStep(
      'khs_semesters',
      () => _getKhs.getSemesters(npm: npm, password: password),
    );

    // Steps 5-7: Process ALL available KHS semesters
    final List<String> khsErrors = [];
    for (final semesterEntry in semesters) {
      final detail = '${semesterEntry.tahunAjaran} ${semesterEntry.semester}';
      try {
        // Step 5: Download KHS PDF
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

        // Step 6: Extract KHS
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

        // Step 7: Fetch KHS data
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
