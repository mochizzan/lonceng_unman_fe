// profile - Action button widget
//
// "Pengaturan" full-width tonal button (DESIGN.md §5.4:
// Secondary Container / On Secondary Container, radius 24).
// Navigates to SettingsPage.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_button.dart';

/// Full-width tonal action button for navigating to settings.
///
/// Uses `Secondary Container` / `On Secondary Container` colors via
/// [Theme.of] (no hardcoded colors) with a 24px radius,
/// per DESIGN.md §5.4.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      onPressed: () {
        context.pushNamed(RouteNames.settings);
      },
      fullWidth: true,
      secondary: true,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_outlined),
          SizedBox(width: 8),
          Text(
            AppStrings.profileSettingsButton,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
