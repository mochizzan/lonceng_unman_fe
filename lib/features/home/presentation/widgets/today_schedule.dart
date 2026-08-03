// home - Today Schedule Timeline widget
//
// Vertical timeline of today's classes with status indicators.
// Matches the HTML template's jadwal hari ini section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';

class TodaySchedule extends StatelessWidget {
  const TodaySchedule({super.key, required this.items, this.onSeeAllTap});

  final List<ScheduleItemEntity> items;
  final VoidCallback? onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: title + see all
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Jadwal Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            TextButton(
              onPressed: onSeeAllTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: cs.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Timeline items
        if (items.isEmpty)
          Text(
            'Tidak ada jadwal hari ini',
            style: TextStyle(color: cs.onSurfaceVariant),
          )
        else
          Column(
            children: List.generate(items.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < items.length - 1 ? 20 : 0,
                ),
                child: _TimelineItem(
                  item: items[index],
                  isFirst: index == 0,
                  isLast: index == items.length - 1,
                ),
              );
            }),
          ),
      ],
    );
  }
}

/// A pulsing dot for "sedang berlangsung" items.
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
            builder: (context, value, child) {
              return Opacity(
                opacity: 0.4 * value,
                child: Transform.scale(
                  scale: 0.6 + value * 1.0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final ScheduleItemEntity item;
  final bool isFirst;
  final bool isLast;

  static const _fallbackSuccess = Color(0xFF2E7D32);

  Color _getSuccessColor(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    return appColors?.success ?? _fallbackSuccess;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final successColor = _getSuccessColor(context);
    final isOngoing = item.status == ScheduleStatus.ongoing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot column (fixed width)
        SizedBox(
          width: 24,
          child: Column(
            children: [
              // Dot
              if (isOngoing)
                const SizedBox(height: 6)
              else
                const SizedBox(height: 4),
              _buildDot(cs, successColor, isOngoing),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: isOngoing
              ? _buildOngoingCard(context, cs, successColor)
              : _buildCompactItem(cs),
        ),
      ],
    );
  }

  Widget _buildDot(ColorScheme cs, Color successColor, bool isOngoing) {
    if (isOngoing) {
      return SizedBox(
        width: 14,
        height: 14,
        child: _PulsingDot(color: successColor),
      );
    }
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
    );
  }

  Widget _buildOngoingCard(
    BuildContext context,
    ColorScheme cs,
    Color successColor,
  ) {
    final timeRange =
        '${_formatTime(item.startTime)} – ${_formatTime(item.endTime)}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sedang Berlangsung',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: successColor,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                timeRange,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.courseName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                item.room,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Icon(Icons.groups, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                item.group ?? '-',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItem(ColorScheme cs) {
    final timeStr = _formatTime(item.startTime);
    final isPast = item.status == ScheduleStatus.completed;
    final opacity = isPast ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.courseName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    item.room,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
