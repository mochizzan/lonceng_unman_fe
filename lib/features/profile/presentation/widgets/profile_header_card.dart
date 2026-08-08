// profile - Profile Header Card widget
//
// Top profile card: avatar (with camera overlay btn) + name + study-program badge.
// Background = primaryContainer, name = onPrimaryContainer, badge =
// secondaryContainer/onSecondaryContainer.
// All colors via Theme.of(context).colorScheme / AppColors — no hardcoded colors.
// Matches DESIGN.md §5.4 Profile Header Card + HTML template lines 36-46.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/theme/app_shadows.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_avatar.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key, required this.data});

  final ProfileEntity data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sp(context, 32)),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(sp(context, 32)),
        boxShadow: AppShadows.cardResponsive(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Avatar (interaktif: ketuk ikon kamera untuk ganti foto) ---
          ProfileAvatar(avatarUrl: data.avatarUrl),
          SizedBox(height: sp(context, 16)),
          // --- Name ---
          Text(
            data.userName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onPrimaryContainer,
              fontSize: responsiveFontSize(context, 24),
            ),
          ),
          SizedBox(height: sp(context, 8)),
          // --- Study program badge ---
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: sp(context, 16),
              vertical: sp(context, 6),
            ),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(sp(context, 999)),
            ),
            child: Text(
              data.studyProgram,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: responsiveFontSize(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
