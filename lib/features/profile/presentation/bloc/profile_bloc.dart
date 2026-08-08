// profile - BLoC
//
// Manages state for the profile screen: fetches data via usecase
// and emits state changes.
// Follows the same pattern as jadwal's JadwalBloc.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/errors/bloc_error_handler.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState>
    with BlocErrorHandler {
  final GetProfile _getProfile;

  ProfileBloc(this._getProfile) : super(const ProfileInitial()) {
    on<ProfileFetchRequested>(_onFetchRequested);
    on<ProfileRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onFetchRequested(
    ProfileFetchRequested event,
    Emitter emit,
  ) async {
    emit(ProfileLoading());
    try {
      final data = await _getProfile();
      emit(ProfileLoaded(data: data));
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      emit(ProfileError(handleError(e)));
    }
  }

  Future<void> _onRefreshRequested(
    ProfileRefreshRequested event,
    Emitter emit,
  ) async {
    try {
      // Fetch from remote API first, then re-read from (now fresh) cache.
      // Do NOT emit ProfileLoading — keep current data visible during refresh.
      await _getProfile.refreshFromRemote();
      final data = await _getProfile();
      emit(ProfileLoaded(data: data));
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      // Keep previous loaded state on refresh failure — no error screen.
      if (state is ProfileLoaded) return;
      emit(ProfileError(handleError(e)));
    }
  }
}
