import 'dart:async';

import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';

/// Orchestrates the post-login data initialization pipeline.
///
/// Pipeline (3 API calls on home page):
///   1. Download KRS PDF  → POST /api/v1/lms/krs
///   2. Extract KRS       → POST /api/v1/lms/krs/extract
///   3. Fetch KRS data    → POST /api/v1/lms/krs/data
///
/// Login (1 call on login page):
///   POST /api/v1/lms/login
///
/// Total: 4 endpoint hits.
class DataInitializationRemoteDataSource {
  final GetKrs _getKrs;

  DataInitializationRemoteDataSource({required this._getKrs});

  Stream<DataInitStatus> initialize({
    required String npm,
    required String password,
  }) async* {
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
