// jadwal - BLoC
//
// Manages state for the jadwal screen: fetches data via usecase
// and emits state changes.
// Follows the same pattern as home's HomeBloc.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_event.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/errors/bloc_error_handler.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_state.dart';

class JadwalBloc extends Bloc<JadwalEvent, JadwalState> with BlocErrorHandler {
  final GetJadwal _getJadwal;

  JadwalBloc(this._getJadwal) : super(const JadwalInitial()) {
    on<JadwalFetchRequested>(_onFetchRequested);
    on<JadwalRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onFetchRequested(
    JadwalFetchRequested event,
    Emitter emit,
  ) async {
    emit(JadwalLoading());
    try {
      final data = await _getJadwal();
      emit(JadwalLoaded(data: data));
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      emit(JadwalError(handleError(e)));
    }
  }

  Future<void> _onRefreshRequested(
    JadwalRefreshRequested event,
    Emitter emit,
  ) async {
    try {
      final data = await _getJadwal();
      emit(JadwalLoaded(data: data));
    } catch (_) {
      // Keep previous JadwalLoaded state.
      // Do NOT emit JadwalError — schedule stays visible.
    }
  }
}
