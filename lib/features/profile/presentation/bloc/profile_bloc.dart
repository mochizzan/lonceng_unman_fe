// profile - BLoC
//
// Manages state for the profile screen: fetches data via usecase
// and emits state changes.
// Follows the same pattern as jadwal's JadwalBloc.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/errors/bloc_error_handler.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState>
    with BlocErrorHandler {
  final GetProfile _getProfile;
  final BioCacheService _bioCacheService;

  ProfileBloc(this._getProfile, this._bioCacheService)
    : super(const ProfileInitial()) {
    on<ProfileFetchRequested>(_onFetchRequested);
    on<ProfileRefreshRequested>(_onRefreshRequested);
    on<ProfileBioUpdated>(_onBioUpdated);
    on<ProfileBioDeleted>(_onBioDeleted);
  }

  Future<void> _onFetchRequested(
    ProfileFetchRequested event,
    Emitter emit,
  ) async {
    emit(ProfileLoading());
    try {
      final data = await _getProfile();

      // Check if bio cache was corrupted during initialization
      if (_bioCacheService.wasCorrupted) {
        _bioCacheService.clearCorruptionFlag();
        emit(ProfileLoaded(data: data));
        // Emit error after loaded to show snackbar
        emit(
          const ProfileError(
            'Bio cache mengalami kerusakan. Bio telah direset.',
          ),
        );
        return;
      }

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

  Future<void> _onBioUpdated(ProfileBioUpdated event, Emitter emit) async {
    try {
      // Get current NPM from loaded profile
      if (state is ProfileLoaded) {
        final currentData = (state as ProfileLoaded).data;
        await _bioCacheService.saveBio(npm: currentData.npm, bio: event.bio);
        // Reload profile to reflect changes
        final data = await _getProfile();
        emit(ProfileLoaded(data: data));
      }
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      // Keep current state on error — bottom sheet handles snackbar
      emit(ProfileError(handleError(e)));
    }
  }

  Future<void> _onBioDeleted(ProfileBioDeleted event, Emitter emit) async {
    try {
      // Get current NPM from loaded profile
      if (state is ProfileLoaded) {
        final currentData = (state as ProfileLoaded).data;
        await _bioCacheService.deleteBio(npm: currentData.npm);
        // Reload profile to reflect changes
        final data = await _getProfile();
        emit(ProfileLoaded(data: data));
      }
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      // Keep current state on error — bottom sheet handles snackbar
      emit(ProfileError(handleError(e)));
    }
  }
}
