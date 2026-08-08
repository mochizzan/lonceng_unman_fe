// profile - Profile Bio Section widget
//
// "Tentang" tab content: bio text card.
// All colors routed through Theme.of(context).colorScheme — no hardcoded
// color values.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';

/// "Tentang" tab content for the profile screen.
///
/// Renders the student bio as a surface-variant/40 card.
/// IPK and SKS are shown on the Home page to avoid duplication.
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
      ],
    );
  }
}
