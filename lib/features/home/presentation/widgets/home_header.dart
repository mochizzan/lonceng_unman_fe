// home - Header widget (top app bar)
//
// Sticky header with date, greeting, notification bell, and profile avatar.
// Matches the HTML template's `<header>` section.

import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Halo, $userName 👋',
                  style: TextStyle(
                    fontSize: 22,
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
                      const Icon(Icons.notifications_none, size: 22),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: cs.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Profile avatar
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primaryContainer, width: 2),
                    ),
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              width: 44,
                              height: 44,
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
