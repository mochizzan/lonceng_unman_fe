// home - Today Schedule Timeline widget
//
// Vertical timeline of today's classes with status indicators.
// Matches the HTML template's jadwal hari ini section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart' hide AppColors;
import 'package:lonceng_unman_fe/core/theme/theme.dart';
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
              AppStrings.homeScheduleTitle,
              style: TextStyle(
                fontSize: AppDimens.text2XL,
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
                    AppStrings.homeViewAll,
                    style: TextStyle(
                      fontSize: AppDimens.textBase,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimens.space2),
                  Icon(
                    Icons.chevron_right,
                    size: AppDimens.textXL,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space16),
        // Timeline items
        if (items.isEmpty)
          Text(
            AppStrings.homeNoSchedule,
            style: TextStyle(color: cs.onSurfaceVariant),
          )
        else
          Column(
            children: List.generate(items.length, (index) {
              return IntrinsicHeight(
                child: _TimelineItem(
                  item: items[index],
                  isFirst: index == 0,
                  isLast: index == items.length - 1,
                  index: index,
                ),
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
    _controller = AnimationController(vsync: this, duration: AppDurations.slow)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimens.dotLG,
      height: AppDimens.dotLG,
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
                  width: AppDimens.dotLG,
                  height: AppDimens.dotLG,
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
            width: AppDimens.dotSM,
            height: AppDimens.dotSM,
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
    required this.index,
  });

  final ScheduleItemEntity item;
  final bool isFirst;
  final bool isLast;
  final int index;

  Color _getSuccessColor(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    return appColors?.success ?? Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final successColor = _getSuccessColor(context);
    final isOngoing = item.status == ScheduleStatus.ongoing;

    // Standard Flutter timeline pattern: Row with dot column + content
    // Line uses Expanded to follow content height automatically
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot column (fixed width)
        SizedBox(
          width: AppDimens.space24,
          child: Column(
            children: [
              _buildDot(cs, successColor, isOngoing),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: AppDimens.borderWidthMedium,
                    color: cs.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.space20),
            child: isOngoing
                ? _buildOngoingCard(context, cs, successColor)
                : _buildUpcomingCard(cs, index),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(ColorScheme cs, Color successColor, bool isOngoing) {
    if (isOngoing) {
      return SizedBox(
        width: AppDimens.dotLG,
        height: AppDimens.dotLG,
        child: _PulsingDot(color: successColor),
      );
    }
    return Container(
      width: AppDimens.dotLG,
      height: AppDimens.dotLG,
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: cs.outlineVariant,
          width: AppDimens.borderWidthThin,
        ),
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
      padding: const EdgeInsets.all(AppDimens.space14),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.homeStatusOngoing,
                style: TextStyle(
                  fontSize: AppDimens.textXS,
                  fontWeight: FontWeight.bold,
                  color: successColor,
                  letterSpacing: AppDimens.letterSpacingWide,
                ),
              ),
              Text(
                timeRange,
                style: TextStyle(
                  fontSize: AppDimens.textSM,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            item.courseName,
            style: TextStyle(
              fontSize: AppDimens.textXL,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Row(
            children: [
              Icon(Icons.location_on, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: AppDimens.space4),
              Text(
                item.room,
                style: TextStyle(
                  fontSize: AppDimens.textSM,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Icon(Icons.groups, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: AppDimens.space4),
              Text(
                item.group ?? '-',
                style: TextStyle(
                  fontSize: AppDimens.textSM,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(ColorScheme cs, int index) {
    final timeStr = _formatTime(item.startTime);
    // Index 1: secondaryContainer (segera) - softer than primaryContainer
    // Index 2+: surfaceContainerHighest (akan datang)
    final bool isSoon = index == 1;
    final Color bgColor = isSoon
        ? cs.secondaryContainer
        : cs.surfaceContainerHighest;
    final Color textColor = isSoon
        ? cs.onSecondaryContainer
        : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSoon)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.homeStatusUpcoming,
                  style: TextStyle(
                    fontSize: AppDimens.textXS,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: AppDimens.letterSpacingWide,
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: AppDimens.textSM,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          if (isSoon) const SizedBox(height: AppDimens.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.courseName,
                    style: TextStyle(
                      fontSize: AppDimens.textLG,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 15,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppDimens.space4),
                      Text(
                        item.room,
                        style: TextStyle(
                          fontSize: AppDimens.textSM,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!isSoon)
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: AppDimens.textSM,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
            ],
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
