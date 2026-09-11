import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/app_durations.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/core/utils/network_error_classifier.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';

/// Max wall-clock time for the full post-login pipeline.
const Duration kDataInitTimeout = AppDurations.dataInitPipeline;

class DataInitBloc extends Bloc<DataInitEvent, DataInitBlocState> {
  final GetDataInitialization _getDataInit;
  final ConnectivityService? _connectivity;
  bool _isRunning = false;

  String? _lastNpm;
  String? _lastPassword;
  bool _lastForceRefresh = true;
  bool _lastIsPullRefresh = false;
  String? _pausedStep;
  bool _pausedSkippable = false;

  DataInitBloc(this._getDataInit, {ConnectivityService? connectivity})
    : _connectivity = connectivity ?? Services.get<ConnectivityService>(),
      super(const DataInitIdle()) {
    on<DataInitStarted>(_onStarted);
    on<DataInitReset>(_onReset);
    on<DataInitRetry>(_onRetry);
    on<DataInitSkip>(_onSkip);
  }

  /// Whether a pipeline run is currently in progress.
  bool get isRunning => _isRunning;

  Future<void> _onStarted(
    DataInitStarted event,
    Emitter<DataInitBlocState> emit,
  ) async {
    debugPrint(
      '[DATA_INIT] _onStarted called — forceRefresh=${event.forceRefresh}',
    );
    // Fail-fast: if the device is offline, emit paused so the user can
    // retry without a full logout. If we are already paused on a
    // skippable step (KRS/KHS), preserve that checkpoint — do NOT
    // overwrite it with no_connection:false or Lewati will vanish.
    if (_connectivity?.isOnline == false) {
      if (_pausedStep != null) {
        debugPrint(
          '[DATA_INIT] Offline detected while paused at $_pausedStep — preserve paused (skippable=$_pausedSkippable)',
        );
        // Re-emit same paused so UI stays; do not clear checkpoint.
        final current = state;
        if (current is DataInitPaused) {
          // Already showing paused — keep as-is, no state change needed.
          return;
        }
        // Fallback if state somehow not Paused but we have checkpoint.
        emit(
          DataInitPaused(
            AppStrings.dataInitNoConnection,
            failedStep: _pausedStep!,
            skippable: _pausedSkippable,
          ),
        );
        return;
      }
      debugPrint('[DATA_INIT] Offline detected — fail-fast (paused)');
      _pausedStep = 'no_connection';
      _pausedSkippable = false;
      emit(
        const DataInitPaused(
          AppStrings.dataInitNoConnection,
          failedStep: 'no_connection',
          skippable: false,
        ),
      );
      return;
    }
    // Guard against concurrent / duplicate starts (login + shell bootstrap).
    if (_isRunning) {
      debugPrint('[DATA_INIT] Already running — SKIP');
      return;
    }

    _lastNpm = event.npm;
    _lastPassword = event.password;
    _lastForceRefresh = event.forceRefresh;
    _lastIsPullRefresh = event.isPullRefresh;
    _pausedStep = null;
    _pausedSkippable = false;

    _isRunning = true;
    debugPrint('[DATA_INIT] Emitting scrapingProfile');
    emit(const DataInitInProgress(DataInitStatus.scrapingProfile));

    try {
      final stream =
          _getDataInit(
            npm: event.npm,
            password: event.password,
            forceRefresh: event.forceRefresh,
            isPullRefresh: event.isPullRefresh,
          ).timeout(
            kDataInitTimeout,
            onTimeout: (sink) {
              sink.addError(
                TimeoutException(
                  'Inisialisasi data melebihi batas waktu',
                  kDataInitTimeout,
                ),
              );
              sink.close();
            },
          );

      // Emit from within the handler so BLoC owns the Emitter lifecycle.
      await for (final progress in stream) {
        final status = progress.status;
        debugPrint(
          '[DATA_INIT] Stream emit: $status${progress.detail != null ? ' (${progress.detail})' : ''}',
        );
        if (status == DataInitStatus.completed ||
            status == DataInitStatus.completedWithErrors) {
          debugPrint('[DATA_INIT] Emitting DataInitSuccess');
          _pausedStep = null;
          _pausedSkippable = false;
          emit(const DataInitSuccess());
        } else if (status == DataInitStatus.failed) {
          debugPrint('[DATA_INIT] Emitting DataInitFailure');
          emit(const DataInitFailure('Gagal memuat data akademik'));
        } else {
          emit(DataInitInProgress(status, detail: progress.detail));
        }
      }

      // If stream ended without completed/failed, treat as success only when
      // the last emitted state was already success; otherwise fail soft.
      if (state is DataInitInProgress) {
        emit(
          const DataInitFailure(
            'Pipeline selesai tanpa status completed',
            failedStep: 'unknown',
          ),
        );
      }
    } catch (error) {
      debugPrint('[DATA_INIT] Exception: $error');
      final friendlyMessage = ErrorHandler.toHumanReadable(error);
      String? step;
      if (error is DataInitStepException) {
        step = error.step;
      } else if (error is TimeoutException) {
        step = 'timeout';
      }
      final net = isNetworkError(error, failedStep: step);
      if (net) {
        final skippable = step == null ? false : !isProfileStep(step);
        _pausedStep = step ?? 'unknown';
        _pausedSkippable = skippable;
        emit(
          DataInitPaused(
            friendlyMessage,
            failedStep: _pausedStep!,
            skippable: skippable,
          ),
        );
      } else {
        emit(DataInitFailure(friendlyMessage, failedStep: step));
      }
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _onRetry(
    DataInitRetry event,
    Emitter<DataInitBlocState> emit,
  ) async {
    if (_isRunning) return;
    // Fresh login Failure (e.g. profile_scrape_2) has _pausedStep==null —
    // still allow full restart if we have credentials.
    var failedStep = _pausedStep;
    if (failedStep == null) {
      final s = state;
      if (s is DataInitFailure) failedStep = s.failedStep;
    }
    if (failedStep == null) return;
    if (_lastNpm == null || _lastPassword == null) return;

    // Profile steps (or any non-krs/khs) have no safe checkpoint — full restart.
    final isKrsOrKhs =
        failedStep.startsWith('krs') || failedStep.startsWith('khs');
    if (!isKrsOrKhs) {
      add(
        DataInitStarted(
          npm: _lastNpm!,
          password: _lastPassword!,
          forceRefresh: _lastForceRefresh,
          isPullRefresh: _lastIsPullRefresh,
        ),
      );
      return;
    }

    // Granular resume: reuse cached profile, skip scraping/gettingProfile/fetchingPhoto
    if (_connectivity?.isOnline == false) {
      // Still offline — keep paused, user can try again
      return;
    }
    _isRunning = true;
    // Emit the failed step as InProgress so UI shows correct status again
    final resumeStatus = _statusForStep(failedStep);
    emit(DataInitInProgress(resumeStatus));
    try {
      final stream = _getDataInit.repository
          .resumeFrom(
            failedStep: failedStep,
            npm: _lastNpm!,
            password: _lastPassword!,
            forceRefresh: _lastForceRefresh,
          )
          .timeout(
            kDataInitTimeout,
            onTimeout: (sink) {
              sink.addError(
                TimeoutException(
                  'Inisialisasi data melebihi batas waktu',
                  kDataInitTimeout,
                ),
              );
              sink.close();
            },
          );
      await for (final progress in stream) {
        final status = progress.status;
        if (status == DataInitStatus.completed ||
            status == DataInitStatus.completedWithErrors) {
          _pausedStep = null;
          _pausedSkippable = false;
          emit(const DataInitSuccess());
        } else if (status == DataInitStatus.failed) {
          emit(const DataInitFailure('Gagal memuat data akademik'));
        } else {
          emit(DataInitInProgress(status, detail: progress.detail));
        }
      }
      if (state is DataInitInProgress) {
        emit(
          const DataInitFailure(
            'Pipeline selesai tanpa status completed',
            failedStep: 'unknown',
          ),
        );
      }
    } catch (error) {
      final friendlyMessage = ErrorHandler.toHumanReadable(error);
      String? step;
      if (error is DataInitStepException) {
        step = error.step;
      } else if (error is TimeoutException) {
        step = 'timeout';
      }
      final net = isNetworkError(error, failedStep: step);
      if (net) {
        final skippable = step == null ? false : !isProfileStep(step);
        _pausedStep = step ?? failedStep;
        _pausedSkippable = skippable;
        emit(
          DataInitPaused(
            friendlyMessage,
            failedStep: _pausedStep!,
            skippable: skippable,
          ),
        );
      } else {
        emit(DataInitFailure(friendlyMessage, failedStep: step));
      }
    } finally {
      _isRunning = false;
    }
  }

  DataInitStatus _statusForStep(String step) {
    if (step.startsWith('krs_download')) return DataInitStatus.downloadingKrs;
    if (step.startsWith('krs_extract')) return DataInitStatus.extractingKrs;
    if (step.startsWith('krs_data')) return DataInitStatus.fetchingKrsData;
    if (step.startsWith('khs_semesters')) {
      return DataInitStatus.fetchingKhsSemesters;
    }
    if (step.startsWith('khs_download')) return DataInitStatus.downloadingKhs;
    if (step.startsWith('khs_extract')) return DataInitStatus.extractingKhs;
    if (step.startsWith('khs_data')) return DataInitStatus.fetchingKhsData;
    return DataInitStatus.downloadingKrs;
  }

  void _onSkip(DataInitSkip event, Emitter<DataInitBlocState> emit) {
    if (_isRunning) return;
    if (_pausedStep == null) return;
    if (!_pausedSkippable) return;
    final step = _pausedStep!;
    _pausedStep = null;
    _pausedSkippable = false;
    emit(DataInitSuccess(isPartial: true, skippedSteps: [step]));
  }

  void _onReset(DataInitReset event, Emitter<DataInitBlocState> emit) {
    if (_isRunning) return;
    _pausedStep = null;
    _pausedSkippable = false;
    emit(const DataInitIdle());
  }
}
