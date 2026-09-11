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
  String _selectedDay = '';
  bool _dayManuallySelected = false;

  JadwalBloc(this._getJadwal) : super(const JadwalInitial()) {
    on<JadwalFetchRequested>(_onFetchRequested);
    on<JadwalRefreshRequested>(_onRefreshRequested);
    on<JadwalDaySelected>(_onDaySelected);
  }

  Future<void> _onFetchRequested(
    JadwalFetchRequested event,
    Emitter emit,
  ) async {
    emit(JadwalLoading());
    try {
      final data = await _getJadwal();
      _selectedDay = data.selectedDay;
      emit(
        JadwalLoaded(data: data, selectedDay: _selectedDay, days: data.days),
      );
    } on AlumniException {
      // ALUMNI is not an error — emit empty schedule via datasource's isAlumni model.
      // Re-fetch via datasource already returns empty; this catches any pass-through.
      try {
        final data = await _getJadwal();
        _selectedDay = data.selectedDay;
        emit(
          JadwalLoaded(data: data, selectedDay: _selectedDay, days: data.days),
        );
      } catch (_) {
        emit(
          JadwalError(
            handleError(AlumniException('KRS tidak tersedia (STATUS ALUMNI)')),
          ),
        );
      }
      return;
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      if (isAlumniError(e)) {
        try {
          final data = await _getJadwal();
          _selectedDay = data.selectedDay;
          emit(
            JadwalLoaded(
              data: data,
              selectedDay: _selectedDay,
              days: data.days,
            ),
          );
          return;
        } catch (_) {}
      }
      emit(JadwalError(handleError(e)));
    }
  }

  Future<void> _onRefreshRequested(
    JadwalRefreshRequested event,
    Emitter emit,
  ) async {
    try {
      final data = await _getJadwal();
      if (!_dayManuallySelected) {
        _selectedDay = data.selectedDay;
      }
      emit(
        JadwalLoaded(data: data, selectedDay: _selectedDay, days: data.days),
      );
    } catch (_) {
      // Keep previous JadwalLoaded state.
      // Do NOT emit JadwalError — schedule stays visible.
    }
  }

  void _onDaySelected(JadwalDaySelected event, Emitter emit) {
    _dayManuallySelected = true;
    _selectedDay = event.day;
    if (state is JadwalLoaded) {
      final current = state as JadwalLoaded;
      emit(
        JadwalLoaded(
          data: current.data,
          selectedDay: event.day,
          days: current.days,
        ),
      );
    }
  }
}
