import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_card.dart';
import 'package:lonceng_unman_fe/shared/widgets/pulsing_dot.dart';

class JadwalTimeline extends StatelessWidget {
  const JadwalTimeline({super.key, required this.items, this.selectedDay = ''});

  final List<ScheduleItemEntity> items;
  final String selectedDay;

  /// Returns the Indonesian day name for a given DateTime.
  String _dayName(DateTime date) {
    const names = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return names[date.weekday - 1];
  }

  /// Groups items by day name, preserving order.
  Map<String, List<ScheduleItemEntity>> _groupByDay() {
    final map = <String, List<ScheduleItemEntity>>{};
    for (final item in items) {
      final day = _dayName(item.startTime);
      map.putIfAbsent(day, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      // Show different message based on whether "Semua" or a specific day is selected
      final message = (selectedDay == 'Semua' || selectedDay.isEmpty)
          ? 'Tidak ada jadwal kuliah minggu ini'
          : 'Tidak ada kelas hari $selectedDay';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final showDayHeaders = selectedDay == 'Semua';

    if (showDayHeaders) {
      final grouped = _groupByDay();
      final dayOrder = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      final sortedDays = dayOrder.where((d) => grouped.containsKey(d)).toList();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
        child: Column(
          children: sortedDays.expand((day) {
            final dayItems = grouped[day]!;
            return [
              // Day header
              Padding(
                padding: const EdgeInsets.only(
                  top: AppDimens.space8,
                  bottom: AppDimens.space12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space12,
                        vertical: AppDimens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusFull,
                        ),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: AppDimens.textSM,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Container(height: 1, color: cs.outlineVariant),
                    ),
                  ],
                ),
              ),
              // Items for this day
              ...dayItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final globalIdx = items.indexOf(item);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Column(
                          children: [
                            _buildDot(cs, item),
                            if (idx < dayItems.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: cs.outlineVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimens.space16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimens.space16,
                          ),
                          child: JadwalCard(item: item, index: globalIdx),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ];
          }).toList(),
        ),
      );
    }

    // Single day view (no day headers)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
      child: Column(
        children: List.generate(items.length, (index) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
