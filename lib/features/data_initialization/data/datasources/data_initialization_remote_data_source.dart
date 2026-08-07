import 'dart:async';

import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';

/// Exception thrown when a pipeline step fails.
/// Carries the step name and original error for diagnostics.
class DataInitStepException implements Exception {
  final String step;
  final String message;
  final Object? originalError;

  const DataInitStepException(this.step, this.message, [this.originalError]);

  @override
  String toString() => 'DataInitStepException($step): $message';
}

/// Orchestrates the full post-login data initialization pipeline.
///
/// Chains LMS API calls in sequence, yielding [DataInitStatus] updates
/// via a stream so the UI can show progress.
/// Throws [DataInitStepException] on any step failure.
class DataInitializationRemoteDataSource {
  final GetKrs _getKrs;
  final GetKhs _getKhs;

  DataInitializationRemoteDataSource({
    required this._getKrs,
    required this._getKhs,
  });

  Stream<DataInitStatus> initialize({
    required String npm,
    required String password,
  }) async* {
    // Step 1: Download KRS PDF + Fetch KHS semesters (PARALLEL)
    yield DataInitStatus.downloadingKrs;
    final semesters = await _runStep('download', () async {
      final results = await Future.wait([
        _getKrs.download(npm: npm, password: password),
        _getKhs.getSemesters(npm: npm, password: password),
      ]);
      return results[1] as List<KhsSemesterEntity>;
    });

    // Step 2: Pick latest semester
    yield DataInitStatus.fetchingSemesters;
    if (semesters.isEmpty) {
      throw const DataInitStepException('semesters', 'No semesters found');
    }
    final latest = semesters.last; // latest semester

    // Step 3: Download KHS PDF
    yield DataInitStatus.downloadingKhs;
    await _runStep(
      'khs_download',
      () => _getKhs.download(
        npm: npm,
        password: password,
        tahunAjaran: latest.tahunAjaran,
        semester: latest.semester,
      ),
    );

    // Step 4: Extract KRS
    yield DataInitStatus.extractingKrs;
    await _runStep(
      'krs_extract',
      () => _getKrs.extract(npm: npm, password: password),
    );

    // Step 5: Extract KHS
    yield DataInitStatus.extractingKhs;
    await _runStep(
      'khs_extract',
      () => _getKhs.extract(
        npm: npm,
        password: password,
        tahunAjaran: latest.tahunAjaran,
        semester: latest.semester,
      ),
    );

    // Step 6: Fetch KRS data
    yield DataInitStatus.fetchingKrsData;
    final krsData = await _runStep('krs_data', () => _getKrs(npm: npm));
    if (krsData.krs.mataKuliah.isEmpty) {
      throw const DataInitStepException('krs_data', 'Data KRS kosong');
    }

    // Step 7: Fetch KHS data
    yield DataInitStatus.fetchingKhsData;
    final khsData = await _runStep(
      'khs_data',
      () => _getKhs(
        npm: npm,
        tahunAjaran: latest.tahunAjaran,
        semester: latest.semester,
      ),
    );
    if (khsData.khs.mataKuliah.isEmpty) {
      throw const DataInitStepException('khs_data', 'Data KHS kosong');
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
