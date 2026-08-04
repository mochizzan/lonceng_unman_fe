// jadwal - Day Selector widget
//
// Horizontal scrollable row of day pills.
// Active day uses primary / onPrimary with shadow;
// inactive days use surfaceContainerHighest / onSurfaceVariant.
// Matches DESIGN.md §5.3 day selector.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

class JadwalDaySelector extends StatelessWidget {
  const JadwalDaySelector({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<String> days;
  final String selectedDay;
  final ValueChanged<String> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space8,
        ),
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;

          final bgColor = isSelected ? cs.primary : cs.surfaceContainerHighest;
          final textColor = isSelected ? cs.onPrimary : cs.onSurfaceVariant;

          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  fontSize: AppDimens.textBase,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
