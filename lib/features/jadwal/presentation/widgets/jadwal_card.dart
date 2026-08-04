// jadwal - Jadwal Card widget
//
// Individual schedule item card for the weekly timeline.
// Ongoing class → bg = primaryContainer / text = onPrimaryContainer
// Upcoming → bg = surface / border = surfaceContainerHighest / accent bar
// All colors come from Theme.of(context).colorScheme — no hardcoded values.
// Matches HTML template design spec.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';

class JadwalCard extends StatelessWidget {
  const JadwalCard({super.key, required this.item, required this.index});

  final JadwalScheduleItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOngoing = item.status == JadwalScheduleStatus.ongoing;

    // Background and border
    final bgColor = isOngoing ? cs.primaryContainer : cs.surface;
    final borderColor = isOngoing ? null : cs.surfaceContainerHighest;

    // Accent bar color (upcoming only): tertiary for index 1, secondary for 2+
    Color? accentColor;
    if (!isOngoing) {
      accentColor = index == 1 ? cs.tertiary : cs.secondary;
    }

    // Time badge colors
    final timeBadgeBg = isOngoing
        ? cs.onPrimaryContainer.withValues(alpha: 0.15)
        : cs.surfaceContainerHigh;
    final timeBadgeText = isOngoing
        ? cs.onPrimaryContainer
        : cs.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status label (ongoing only)
            if (isOngoing) ...[
              Text(
                'SEDANG BERLANGSUNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Course name + time badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accent bar (upcoming only)
                if (accentColor != null) ...[
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.courseName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isOngoing
                              ? cs.onPrimaryContainer
                              : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.lecturer ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: isOngoing
                              ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: timeBadgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: timeBadgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              color: isOngoing
                  ? cs.onPrimaryContainer.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            // Location + SKS row
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: isOngoing
                      ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  item.room,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOngoing
                        ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                        : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.confirmation_number,
                  size: 18,
                  color: isOngoing
                      ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  item.sks,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOngoing
                        ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
