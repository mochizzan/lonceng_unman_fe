/// States for the global refresh overlay.
abstract class RefreshOverlayState {
  const RefreshOverlayState();
}

/// Overlay is hidden — no refresh in progress.
class RefreshOverlayHidden extends RefreshOverlayState {
  const RefreshOverlayHidden();
}

/// Overlay is visible, showing a refresh in progress.
class RefreshOverlayVisible extends RefreshOverlayState {
  final String statusText;
  final bool isCompleted;

  const RefreshOverlayVisible({
    required this.statusText,
    this.isCompleted = false,
  });
}
