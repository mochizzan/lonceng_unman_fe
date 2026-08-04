// profile - Action button widget
//
// "Pengaturan" full-width tonal button (DESIGN.md §5.4:
// Secondary Container / On Secondary Container, radius 24).
// Navigates to SettingsPage.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

/// Full-width tonal action button for navigating to settings.
///
/// Uses `Secondary Container` / `On Secondary Container` colors via
/// [Theme.of] (no hardcoded colors) with a 24px radius,
/// per DESIGN.md §5.4.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          context.pushNamed(RouteNames.settings);
        },
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.settings_outlined),
        label: const Text(
          AppStrings.profileSettingsButton,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
