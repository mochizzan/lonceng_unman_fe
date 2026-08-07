import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_card.dart';
import 'package:lonceng_unman_fe/shared/widgets/pulsing_dot.dart';

class JadwalTimeline extends StatelessWidget {
  const JadwalTimeline({super.key, required this.items});

  final List<ScheduleItemEntity> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
      child: Column(
        children: List.generate(items.length, (index) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot column
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _buildDot(cs, items[index]),
                      if (index < items.length - 1)
                        Expanded(
                          child: Container(width: 2, color: cs.outlineVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.space16),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.space16),
                    child: JadwalCard(item: items[index], index: index),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDot(ColorScheme cs, ScheduleItemEntity item) {
    final isOngoing = item.status == ScheduleStatus.ongoing;

    if (isOngoing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: PulsingDot(
          color: cs.primary,
          size: AppDimens.dotMD,
          duration: AppDurations.verySlow,
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant, width: 4),
      ),
      child: Center(
        child: Container(
          width: AppDimens.dotSM,
          height: AppDimens.dotSM,
          decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
