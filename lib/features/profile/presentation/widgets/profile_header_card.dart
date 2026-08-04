// profile - Profile Header Card widget
//
// Top profile card: avatar (with camera overlay btn) + name + study-program badge.
// Background = primaryContainer, name = onPrimaryContainer, badge =
// secondaryContainer/onSecondaryContainer.
// All colors via Theme.of(context).colorScheme / AppColors — no hardcoded colors.
// Matches DESIGN.md §5.4 Profile Header Card + HTML template lines 36-46.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';

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
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            offset: Offset(0, sp(context, 4)),
            blurRadius: sp(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Avatar (relative) with camera button overlay ---
          SizedBox(
            width: sp(context, 112),
            height: sp(context, 112),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.surface,
                        width: sp(context, 4),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(sp(context, 999)),
                      child: data.avatarUrl.isNotEmpty
                          ? Image.network(data.avatarUrl, fit: BoxFit.cover)
                          : Icon(
                              Icons.person,
                              size: sp(context, 48),
                              color: cs.onPrimaryContainer,
                            ),
                    ),
                  ),
                ),
                // Camera button — bottom right of avatar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: sp(context, 40),
                    height: sp(context, 40),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primaryContainer,
                        width: sp(context, 2),
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: sp(context, 20),
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sp(context, 16)),
          // --- Name ---
          Text(
            data.userName,
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
