// home - Header widget (top app bar)
//
// Sticky header with date, greeting, notification bell, and profile avatar.
// Matches the HTML template's `<header>` section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

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
            // Date + greeting
            Column(
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
                  style: TextStyle(
                    fontSize: AppDimens.text5XL,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
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
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              width: AppDimens.avatarMD,
                              height: AppDimens.avatarMD,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person),
                            )
                          : const Icon(Icons.person),
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
