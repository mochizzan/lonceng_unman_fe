import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/utils/format_utils.dart';
import 'package:lonceng_unman_fe/core/widgets/navbar_visibility_notifier.dart';
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
      return _buildEmptyState(context);
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
                          child: JadwalCard(
                            item: item,
                            index: globalIdx,
                            onTap: () => _showClassDetailSheet(context, item),
                          ),
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

    // Single day view — filter to only the selected day
    final filteredItems = items.where((item) {
      final dayName = _dayName(item.startTime);
      return dayName == selectedDay;
    }).toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
      child: Column(
        children: List.generate(filteredItems.length, (index) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _buildDot(cs, filteredItems[index]),
                      if (index < filteredItems.length - 1)
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
                    child: JadwalCard(
                      item: filteredItems[index],
                      index: index,
                      onTap: () =>
                          _showClassDetailSheet(context, filteredItems[index]),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Future<void> _showClassDetailSheet(
    BuildContext context,
    ScheduleItemEntity item,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final timeRange =
        '${formatTime(item.startTime)} - ${formatTime(item.endTime)}';

    // Hide navbar when bottom sheet opens so MainShellScaffold can animate
    // the slide-down. Restored in the finally block after the sheet closes.
    Services.get<NavbarVisibilityNotifier>().hide();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusLG),
          ),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space20,
              vertical: AppDimens.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
                Text(
                  item.courseName,
                  style: TextStyle(
                    fontSize: AppDimens.textLG,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: AppDimens.space8),
                _buildDetailRow(context, 'Waktu', timeRange),
                _buildDetailRow(context, 'Ruang', item.room),
                _buildDetailRow(
                  context,
                  'Dosen',
                  item.lecturer ?? AppStrings.jadwalNullFallback,
                ),
                _buildDetailRow(context, 'SKS', item.sks ?? '-'),
                const SizedBox(height: AppDimens.space16),
              ],
            ),
          );
        },
      );
    } finally {
      // Show navbar again after the bottom sheet closes.
      Services.get<NavbarVisibilityNotifier>().show();
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
