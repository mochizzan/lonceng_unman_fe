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
    // retry without a full logout. Profile has not been fetched yet, so
    // skippable must be false (no Lewati for mandatory profile).
    if (_connectivity?.isOnline == false) {
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
    if (_pausedStep == null) return;
    if (_lastNpm == null || _lastPassword == null) return;
    add(
      DataInitStarted(
        npm: _lastNpm!,
        password: _lastPassword!,
        forceRefresh: _lastForceRefresh,
        isPullRefresh: _lastIsPullRefresh,
      ),
    );
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
