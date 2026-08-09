import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/overlay/cubit/refresh_overlay_state.dart';

/// Cubit that controls the global refresh overlay visibility and status.
///
/// Used by [GlobalRefreshOverlay] to show/hide/update the overlay
/// based on [DataInitBloc] state transitions.
class RefreshOverlayCubit extends Cubit<RefreshOverlayState> {
  RefreshOverlayCubit() : super(const RefreshOverlayHidden());

  /// Show the overlay with the given [statusText].
  void show(String statusText) {
    emit(RefreshOverlayVisible(statusText: statusText));
  }

  /// Update the status text while the overlay is already visible.
  void updateStatus(String statusText) {
    if (state is RefreshOverlayVisible) {
      emit(RefreshOverlayVisible(statusText: statusText));
    }
  }

  /// Mark the overlay as completed and trigger auto-dismiss.
  void complete(String statusText) {
    emit(RefreshOverlayVisible(statusText: statusText, isCompleted: true));
  }

  /// Hide the overlay.
  void hide() {
    emit(const RefreshOverlayHidden());
  }
}
