// profile - BLoC
//
// Manages state for the profile screen: fetches data via usecase
// and emits state changes.
// Follows the same pattern as jadwal's JadwalBloc.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
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
    } on NetworkException catch (e) {
      emit(ProfileError(e.message));
    } on ServerException catch (e) {
      emit(ProfileError(e.message));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    ProfileRefreshRequested event,
    Emitter emit,
  ) async {
    try {
      final data = await _getProfile();
      emit(ProfileLoaded(data: data));
    } on NetworkException catch (e) {
      emit(ProfileError(e.message));
    } on ServerException catch (e) {
      emit(ProfileError(e.message));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
