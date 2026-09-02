import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

/// Modal bottom sheet that lists available academic years for selection.
///
/// Shown via [showModalBottomSheet] from [YearSwitcherButton].
/// Selected year is highlighted with a checkmark.
/// Includes action buttons at the bottom (Pilih / Batal).
class YearPickerSheet extends StatelessWidget {
  const YearPickerSheet({
    super.key,
    required this.years,
    required this.selectedYear,
    required this.onYearSelected,
  });

  /// List of available academic years (e.g. ['2024/2025', '2023/2024']).
  final List<String> years;

  /// Currently selected academic year.
  final String selectedYear;

  /// Callback when a year is selected.
  final ValueChanged<String> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    String tempSelected = selectedYear;

    return Padding(
      key: const Key('year_picker_sheet'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space20,
        vertical: AppDimens.space16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──
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
            // ── Title ──
            Text(
              AppStrings.khsYearPickerTitle,
              style: TextStyle(
                fontSize: AppDimens.textLG,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppDimens.space8),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: AppDimens.space8),
            // ── Year list ──
            Flexible(
              child: StatefulBuilder(
                builder: (context, setLocalState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: years.map((year) {
                        final isSelected = year == tempSelected;
                        return ListTile(
                          title: Text(
                            year,
                            style: TextStyle(
                              fontSize: AppDimens.textMD,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: cs.primary,
                                  size: AppDimens.iconMD,
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  color: cs.outlineVariant,
                                  size: AppDimens.iconMD,
                                ),
                          onTap: () {
                            setLocalState(() {
                              tempSelected = year;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: AppDimens.space12),
            // ── Action buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radius3XL,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.space12,
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      onYearSelected(tempSelected);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radius3XL,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.space12,
                      ),
                    ),
                    child: const Text('Pilih'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
