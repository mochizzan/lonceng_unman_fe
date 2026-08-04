// jadwal - Jadwal Card widget
//
// Individual schedule item card for the weekly timeline.
// Ongoing class → bg = primaryContainer / text = onPrimaryContainer, badge = successColor
// Upcoming/Completed → bg = surfaceContainer / border = surfaceContainerHighest
// All colors come from Theme.of(context).colorScheme or AppColors extension —
// no hardcoded color values.
// Matches DESIGN.md §5.3 timeline list cards.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';

class JadwalCard extends StatelessWidget {
  const JadwalCard({super.key, required this.item});

  final JadwalScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final isOngoing = item.status == JadwalScheduleStatus.ongoing;

    // All colors routed through the theme — never hardcoded.
    // Ongoing (HTML template: bg=primaryContainer yellow)
    final bgColor = isOngoing ? cs.primaryContainer : cs.surfaceContainer;
    final textColor = isOngoing ? cs.onPrimaryContainer : cs.onSurface;
    final borderColor = isOngoing ? Colors.transparent : cs.outlineVariant;
    final successColor = appColors?.success ?? cs.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: status badge + time range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(context, isOngoing, successColor, cs),
              Text(
                '${_formatTime(item.startTime)} – ${_formatTime(item.endTime)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Timeline dot + course name
          Row(
            children: [
              _buildTimelineDot(isOngoing, cs),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.courseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Room
          Row(
            children: [
              Icon(Icons.location_on, size: 15, color: textColor),
              const SizedBox(width: 4),
              Text(
                item.room,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Lecturer
          if (item.lecturer != null)
            Row(
              children: [
                Icon(Icons.person, size: 15, color: textColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.lecturer!,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          if (item.lecturer != null) const SizedBox(height: 6),
          // SKS badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOngoing
                    ? textColor.withValues(alpha: 0.2)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.sks,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge: ongoing → success container; upcoming/completed → outline.
Widget _buildStatusBadge(
  BuildContext context,
  bool isOngoing,
  Color successColor,
  ColorScheme cs,
) {
  final label = switch (isOngoing) {
    true => 'Sedang Berlangsung',
    false => 'Mendatang',
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isOngoing ? successColor : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      border: isOngoing ? null : Border.all(color: cs.outlineVariant, width: 1),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isOngoing
            ? (Theme.of(context).extension<AppColors>()?.onSuccess ??
                  cs.onPrimary)
            : cs.onSurfaceVariant,
      ),
    ),
  );
}

/// Timeline dot indicator at the start of each card.
/// Matches HTML template:
/// - Ongoing: 24px circle, bg=primary, 4px border-background, inner 8px pulsing dot bg=on-primary
/// - Upcoming: 24px circle, bg=outline-variant, 4px border-background, inner 8px dot bg=surface
Widget _buildTimelineDot(bool isOngoing, ColorScheme cs) {
  return Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: isOngoing ? cs.primary : cs.outlineVariant,
      shape: BoxShape.circle,
      border: Border.all(color: cs.surface, width: 4),
    ),
    child: Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isOngoing ? cs.onPrimary : cs.surface,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
