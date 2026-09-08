import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

/// Modal bottom sheet that informs the user they are offline on the login page.
///
/// Shown via [showOfflineInfoBottomSheet] as a modal with scrim. Supports
/// dismiss via "Mengerti" button, drag, and tap outside.
class OfflineInfoBottomSheet extends StatelessWidget {
  const OfflineInfoBottomSheet({super.key, this.onUnderstood});

  /// Called when user taps "Mengerti". If null, just pops the sheet.
  final VoidCallback? onUnderstood;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        sp(context, 24),
        sp(context, 16),
        sp(context, 24),
        MediaQuery.viewInsetsOf(context).bottom +
            sp(context, 24) +
            MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(sp(context, 28)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: sp(context, 40),
              height: sp(context, 4),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(sp(context, 2)),
              ),
            ),
          ),
          SizedBox(height: sp(context, 16)),
          Icon(
            Icons.cloud_off,
            size: sp(context, AppDimens.iconLG),
            color: cs.onSurfaceVariant,
          ),
          SizedBox(height: sp(context, 12)),
          Text(
            AppStrings.loginOfflineSheetTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              fontSize: responsiveFontSize(context, AppDimens.textLG),
            ),
          ),
          SizedBox(height: sp(context, 8)),
          Text(
            AppStrings.loginOfflineBanner,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: responsiveFontSize(context, AppDimens.textSM),
            ),
          ),
          SizedBox(height: sp(context, 24)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('offline_sheet_understood_button'),
              onPressed: () {
                if (onUnderstood != null) {
                  onUnderstood!.call();
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    sp(context, AppDimens.radius3XL),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: sp(context, 16)),
              ),
              child: const Text(AppStrings.loginOfflineSheetAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the offline info modal bottom sheet as an overlapping modal with scrim.
Future<void> showOfflineInfoBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (_) => const OfflineInfoBottomSheet(),
  );
}
