// home - Header widget (top app bar)
//
// Sticky header with date, greeting, notification bell, and profile avatar.
// Matches the HTML template's `<header>` section.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.dateText,
    required this.userName,
    required this.avatarUrl,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  final String dateText;
  final String userName;
  final String avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space20,
        vertical: AppDimens.space16,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Date + greeting (Expanded to prevent overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: AppDimens.textBase,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space2),
                  Text(
                    'Halo, $userName 👋',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: AppDimens.text5XL,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Notification + avatar
            Row(
              children: [
                // Notification bell
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onNotificationTap,
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: AppDimens.text5XL,
                      ),
                      Positioned(
                        top: AppDimens.space4,
                        right: AppDimens.space4,
                        child: Container(
                          width: AppDimens.dotXS,
                          height: AppDimens.dotXS,
                          decoration: BoxDecoration(
                            color: cs.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.space8),
                // Profile avatar
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: AppDimens.avatarMD,
                    height: AppDimens.avatarMD,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primaryContainer,
                        width: AppDimens.borderWidthMedium,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      child: BlocBuilder<AvatarCubit, AvatarState>(
                        builder: (context, state) {
                          final bytes = state.bytes;
                          if (bytes != null && bytes.isNotEmpty) {
                            // 1. Foto lokal hasil crop — prioritas tertinggi.
                            return Image.memory(
                              bytes,
                              width: AppDimens.avatarMD,
                              height: AppDimens.avatarMD,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.person),
                            );
                          }
                          if (avatarUrl.isNotEmpty) {
                            // 2. Foto dari server bila lokal belum ada.
                            return Image.network(
                              avatarUrl,
                              width: AppDimens.avatarMD,
                              height: AppDimens.avatarMD,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.person),
                            );
                          }
                          // 3. Fallback ikon person.
                          return const Icon(Icons.person);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
