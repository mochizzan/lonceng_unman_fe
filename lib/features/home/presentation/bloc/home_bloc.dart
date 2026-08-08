// home - BLoC
//
// Manages state for the home screen: fetches data via usecase
// and emits state changes. The countdown timer is computed
// live in HeroCountdownCard via a Timer.periodic.
// Follows the same pattern as auth's AuthBloc.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/errors/bloc_error_handler.dart';
import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_event.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> with BlocErrorHandler {
  final GetHome _getHome;

  HomeBloc(this._getHome) : super(const HomeInitial()) {
    on<HomeFetchRequested>(_onFetchRequested);
    on<HomeRefreshRequested>(_onRefreshRequested);
    on<HomeFullRefreshRequested>(_onFullRefreshRequested);
  }

  Future<void> _onFetchRequested(HomeFetchRequested event, Emitter emit) async {
    emit(HomeLoading());
    try {
      final data = await _getHome();
      emit(HomeLoaded(data: data));
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      emit(HomeError(handleError(e)));
    }
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter emit,
  ) async {
    try {
      final data = await _getHome();
      emit(HomeLoaded(data: data));
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      // Keep previous loaded state on refresh failure
      if (state is HomeLoaded) return;
      emit(HomeError(handleError(e)));
    }
  }

  Future<void> _onFullRefreshRequested(
    HomeFullRefreshRequested event,
    Emitter emit,
  ) async {
    try {
      // Small delay so DataRefreshOverlay is visible before pipeline starts
      await Future.delayed(const Duration(milliseconds: 500));
      final data = await _getHome();
      emit(HomeLoaded(data: data));
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      // Keep previous loaded state on refresh failure
      if (state is HomeLoaded) return;
      emit(HomeError(handleError(e)));
    }
  }
}
