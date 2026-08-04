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
              return _TimelineItem(
                item: items[index],
                isFirst: index == 0,
                isLast: index == items.length - 1,
              );
            }),
          ),
      ],
    );
  }
}

/// A pulsing dot for "sedang berlangsung" items.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              final scale = 0.6 + (value * 0.8);
              final opacity = (0.8 - value * 0.6).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          // Inner dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
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

    // Use Stack to position dot and line absolutely, matching HTML template
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Stack(
        children: [
          // Vertical line (hidden for last item) - extend into padding gap
          if (!isLast)
            Positioned(
              left: 11, // center of 24px column - 1px (half of 2px line)
              top: 20, // below dot (4px top + 14px dot + 2px gap)
              bottom: -20, // extend 20px below Stack into padding gap
              child: Container(width: 2, color: cs.outlineVariant),
            ),
          // Dot (positioned absolutely on left)
          Positioned(
            left: 5, // center of 24px column - 7px (half of 14px dot)
            top: isOngoing ? 6 : 4,
            child: _buildDot(cs, successColor, isOngoing),
          ),
          // Content (padded left to make room for dot + line)
          Padding(
            padding: const EdgeInsets.only(
              left: 36,
            ), // 24 (dot column) + 12 (gap)
            child: isOngoing
                ? _buildOngoingCard(context, cs, successColor)
                : _buildCompactItem(cs),
          ),
        ],
      ),
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
        color: cs.secondaryContainer,
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
