import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/shared/widgets/offline_info_bottom_sheet.dart';

/// Reusable controller for the offline info modal bottom sheet.
/// Registered as a singleton in [Services] so any page can reuse it
/// without duplicating `_isShowing` / mount guards.
class OfflineSheetController {
  bool _isShowing = false;

  /// Whether the sheet is currently showing.
  bool get isShowing => _isShowing;

  /// Synchronize sheet visibility with [isOnline].
  /// - When offline: show once if [isLoginForm] is true and not already showing.
  /// - When online: dismiss if currently showing.
  void sync(bool isOnline, BuildContext context, {required bool isLoginForm}) {
    if (!context.mounted) return;
    if (!isOnline) {
      if (_isShowing) return;
      if (!isLoginForm) return;
      _show(context);
    } else {
      if (!_isShowing) return;
      _dismiss(context);
    }
  }

  /// Best-effort dismiss if the sheet is showing.
  void dismissIfShowing(BuildContext context) {
    if (!_isShowing) return;
    if (!context.mounted) return;
    if (!Navigator.canPop(context)) {
      _isShowing = false;
      return;
    }
    Navigator.of(context).pop();
  }

  void _show(BuildContext context) {
    _isShowing = true;
    // ignore: discarded_futures
    showOfflineInfoBottomSheet(context).whenComplete(() => _isShowing = false);
  }

  void _dismiss(BuildContext context) {
    if (!context.mounted) return;
    if (!Navigator.canPop(context)) {
      _isShowing = false;
      return;
    }
    Navigator.of(context).pop();
  }
}
