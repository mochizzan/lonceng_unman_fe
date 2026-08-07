// home - Today Schedule Timeline widget
//
// Vertical timeline of today's classes with status indicators.
// Matches the HTML template's jadwal hari ini section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart' hide AppColors;
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/core/utils/format_utils.dart';
import 'package:lonceng_unman_fe/shared/widgets/pulsing_dot.dart';

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
        child: PulsingDot(
          color: successColor,
          size: AppDimens.dotSM,
          duration: AppDurations.slow,
        ),
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
        '${formatTime(item.startTime)} – ${formatTime(item.endTime)}';
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
    final timeStr = formatTime(item.startTime);
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
}
