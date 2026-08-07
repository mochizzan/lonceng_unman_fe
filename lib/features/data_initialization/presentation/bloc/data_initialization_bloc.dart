import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';

class DataInitBloc extends Bloc<DataInitEvent, DataInitBlocState> {
  final GetDataInitialization _getDataInit;
  StreamSubscription<DataInitStatus>? _subscription;

  DataInitBloc(this._getDataInit) : super(const DataInitIdle()) {
    on<DataInitStarted>(_onStarted);
    on<DataInitReset>(_onReset);
  }

  Future<void> _onStarted(
    DataInitStarted event,
    Emitter<DataInitBlocState> emit,
  ) async {
    _subscription?.cancel();
    emit(const DataInitInProgress(DataInitStatus.authenticating));

    _subscription = _getDataInit(npm: event.npm, password: event.password)
        .listen(
          (status) {
            if (status == DataInitStatus.completed) {
              emit(const DataInitSuccess());
            } else {
              emit(DataInitInProgress(status));
            }
          },
          onError: (error) {
            final friendlyMessage = ErrorHandler.toHumanReadable(error);
            String? step;
            if (error is DataInitStepException) {
              step = error.step;
            }
            emit(DataInitFailure(friendlyMessage, failedStep: step));
          },
        );
  }

  void _onReset(DataInitReset event, Emitter<DataInitBlocState> emit) {
    _subscription?.cancel();
    emit(const DataInitIdle());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
