// profile - Profile Bio Section widget
//
// "Tentang" tab content: bio text card + 2-column SKS/IPK stat grid.
// All colors routed through Theme.of(context).colorScheme — no hardcoded
// color values.
// Matches DESIGN.md §5.4 Profile Screen "Tentang" tab + HTML template lines 79-103.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';
import 'package:lonceng_unman_fe/shared/widgets/stat_card.dart';

/// "Tentang" tab content for the profile screen.
///
/// Renders the student bio as a surface-variant/40 card followed by a
/// 2-column grid of stat cards (Total SKS, IPK Terakhir).
class ProfileBioSection extends StatelessWidget {
  const ProfileBioSection({super.key, required this.data});

  final ProfileEntity data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bio = data.bio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Bio card (surface-variant /40) ---
        if (bio != null && bio.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(sp(context, 20)),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(sp(context, 16)),
            ),
            child: Text(
              bio,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: responsiveFontSize(context, 14),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(sp(context, 20)),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(sp(context, 16)),
            ),
            child: Text(
              'Belum ada bio',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: responsiveFontSize(context, 14),
              ),
            ),
          ),
        SizedBox(height: sp(context, 20)),
        // --- Grid stats: Total SKS + IPK Terakhir ---
        Row(
          children: [
            // Total SKS
            Expanded(
              child: StatCard(
                label: 'Total SKS',
                value: '${data.sksTaken} SKS',
                valueColor: cs.primary,
              ),
            ),
            SizedBox(width: sp(context, 12)),
            // IPK Terakhir
            Expanded(
              child: StatCard(
                label: AppStrings.homeIpkTerakhir,
                value: data.gpa.toStringAsFixed(2),
                valueColor: cs.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
