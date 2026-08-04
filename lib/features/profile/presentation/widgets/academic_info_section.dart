// profile - Academic Info Section widget
//
// Academic info card: NPM, Program Studi, Semester rows.
// Each row: a 10x10 rounded-full icon badge (bg = surfaceContainerHighest, icon =
// primary), a secondary label (onSurfaceVariant, 12pt) and a bold value
// (onSurface, 14pt), separated by a outlineVariant/50 divider.
// Container bg = surface, shadow [0,4,12,rgba(0,0,0,0.06)],
// border = outlineVariant/50.
// All colors via Theme.of(context).colorScheme — no hardcoded color values.
// Matches DESIGN.md §5.4 "Info Akademik" + HTML template lines 50-78.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';

/// Academic info card for the profile screen.
///
/// Renders a [Container] with three labeled rows (NPM, Program Studi,
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sp(context, 24)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(sp(context, 20)),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            offset: Offset(0, sp(context, 4)),
            blurRadius: sp(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            icon: Icons.badge,
            label: 'NPM',
            value: data.npm,
          ),
          _buildInfoRow(
            context,
            icon: Icons.account_balance,
            label: 'Program Studi',
            value: data.studyProgram,
          ),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today,
            label: 'Semester',
            value: data.semester,
          ),
        ],
      ),
    );
  }

  /// A single labeled info row: circular icon badge + label/value + divider.
  ///
  /// The icon badge is 10x10 (scaled), rounded-full, with a background of
  /// [ColorScheme.surfaceContainerHighest] and an icon colored [ColorScheme.primary].
  /// The label uses [ColorScheme.onSurfaceVariant] at 12pt; the value uses
  /// [ColorScheme.onSurface] at 14pt, semibold. Rows are separated by a
  /// [ColorScheme.outlineVariant]/50 divider (no divider after the last row).
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            padding: EdgeInsets.only(
              top: sp(context, 12),
              left: sp(context, 52),
            ),
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              height: 1,
              thickness: 1,
            ),
          ),
      ],
    );
  }
}
