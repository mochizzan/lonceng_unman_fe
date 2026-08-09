// navbar_visibility_notifier.dart
//
// Controls bottom navbar visibility when modals (bottom sheets, dialogs)
// are open. MainShellScaffold listens to this and hides the navbar
// when value is true.

import 'package:flutter/foundation.dart';

/// Notifier for bottom navbar visibility.
///
/// Set to `true` when a modal (bottom sheet, dialog) is open.
/// Set to `false` when the modal closes.
/// MainShellScaffold listens and hides/shows the navbar accordingly.
class NavbarVisibilityNotifier extends ValueNotifier<bool> {
  NavbarVisibilityNotifier() : super(false);

  /// Show the navbar (modal closed).
  void show() => value = false;

  /// Hide the navbar (modal open).
  void hide() => value = true;
}
