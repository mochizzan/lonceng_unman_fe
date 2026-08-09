import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/app_durations.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';

/// Max wall-clock time for the full post-login pipeline.
const Duration kDataInitTimeout = AppDurations.dataInitPipeline;

class DataInitBloc extends Bloc<DataInitEvent, DataInitBlocState> {
  final GetDataInitialization _getDataInit;
  bool _isRunning = false;

  DataInitBloc(this._getDataInit) : super(const DataInitIdle()) {
    on<DataInitStarted>(_onStarted);
    on<DataInitReset>(_onReset);
  }

  /// Whether a pipeline run is currently in progress.
  bool get isRunning => _isRunning;

  Future<void> _onStarted(
    DataInitStarted event,
    Emitter<DataInitBlocState> emit,
  ) async {
    // Guard against concurrent / duplicate starts (login + shell bootstrap).
    if (_isRunning) return;

    _isRunning = true;
    emit(const DataInitInProgress(DataInitStatus.scrapingProfile));

    try {
      final stream =
          _getDataInit(
            npm: event.npm,
            password: event.password,
            forceRefresh: event.forceRefresh,
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
        if (status == DataInitStatus.completed ||
            status == DataInitStatus.completedWithErrors) {
          emit(const DataInitSuccess());
        } else if (status == DataInitStatus.failed) {
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
      final friendlyMessage = ErrorHandler.toHumanReadable(error);
      String? step;
      if (error is DataInitStepException) {
        step = error.step;
      } else if (error is TimeoutException) {
        step = 'timeout';
      }
      emit(DataInitFailure(friendlyMessage, failedStep: step));
    } finally {
      _isRunning = false;
    }
  }

  void _onReset(DataInitReset event, Emitter<DataInitBlocState> emit) {
    if (_isRunning) return;
    emit(const DataInitIdle());
  }
}
