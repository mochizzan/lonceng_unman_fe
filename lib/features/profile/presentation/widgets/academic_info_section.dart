// profile - Academic Info Section widget
//
// Academic info card: Program Studi, NPM, Semester rows.
// Each row: a 40x40 circular icon badge (bg = surfaceContainerHighest, icon =
// primary), a secondary label (onSurfaceVariant, 12pt) and a bold value
// (onSurface, 14pt), separated by a outlineVariant/50 divider.
// Container bg = surfaceContainer, shadow [0,4,12,rgba(0,0,0,0.06)],
// border = outlineVariant/50.
// All colors via Theme.of(context).colorScheme — no hardcoded color values.
// Matches DESIGN.md §5.4 "Info Akademik" + HTML template lines 50-78.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/theme/app_shadows.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';

/// Academic info card for the profile screen.
///
/// Renders a [Container] with three labeled rows (Program Studi, NPM,
/// Semester). Each row begins with a circular icon badge whose background
/// is [ColorScheme.surfaceContainerHighest] and whose icon uses [ColorScheme.primary];
/// a secondary label ([ColorScheme.onSurfaceVariant]) sits above a bold value
/// ([ColorScheme.onSurface]). Rows are separated by a [ColorScheme.outlineVariant]
class AcademicInfoSection extends StatelessWidget {
  const AcademicInfoSection({super.key, required this.data});

  final ProfileEntity data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Icon badge(40) + gap(12) = offset where text and divider start.
    const double iconPlusGap = 52;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sp(context, 20)),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(sp(context, 20)),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: AppColors.opacityHigh),
          width: AppDimens.borderWidthThin,
        ),
        boxShadow: AppShadows.cardResponsive(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoRow(
            context,
            icon: Icons.account_balance,
            label: AppStrings.profileProgramStudi,
            value: data.studyProgram,
            iconOffset: iconPlusGap,
          ),
          SizedBox(height: sp(context, 16)),
          _buildInfoRow(
            context,
            icon: Icons.badge,
            label: AppStrings.loginNpmHint,
            value: data.npm,
            iconOffset: iconPlusGap,
          ),
          SizedBox(height: sp(context, 16)),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today,
            label: AppStrings.profileSemester,
            value: data.semester,
            iconOffset: iconPlusGap,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  /// A single labeled info row: circular icon badge + label/value + divider.
  ///
  /// The icon badge is 40x40 (scaled), circular, with a background of
  /// [ColorScheme.surfaceContainerHighest] and an icon colored [ColorScheme.primary].
  /// The label uses [ColorScheme.onSurfaceVariant] at 12pt; the value uses
  /// [ColorScheme.onSurface] at 14pt, semibold. Rows are separated by a
  /// [ColorScheme.outlineVariant]/50 divider (no divider after the last row).
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double iconOffset,
    bool showDivider = true,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular icon badge
            Container(
              width: sp(context, 40),
              height: sp(context, 40),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: sp(context, 20), color: cs.primary),
            ),
            SizedBox(width: sp(context, 12)),
            // Label + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: responsiveFontSize(context, 12),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: responsiveFontSize(context, 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(top: sp(context, 12)),
            child: Row(
              children: [
                SizedBox(width: sp(context, iconOffset)),
                Expanded(
                  child: Divider(
                    color: cs.outlineVariant.withValues(
                      alpha: AppColors.opacityHigh,
                    ),
                    height: 1,
                    thickness: AppDimens.borderWidthThin,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
