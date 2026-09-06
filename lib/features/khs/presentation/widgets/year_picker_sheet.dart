import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

/// Modal bottom sheet that lists available academic years for selection.
///
/// Shown via [showModalBottomSheet] from [KhsAppBarTitle].
/// Tap an item → immediately selects the year and auto-closes.
/// No Pilih/Batal buttons, no radio/check indicators.
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
            // ── Year list (tap → pop + select) / empty ──
            if (years.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.space24,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppDimens.iconLG,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppDimens.space8),
                      Text(
                        'Belum ada tahun ajaran',
                        style: TextStyle(
                          fontSize: AppDimens.textMD,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: years.map((year) {
                      final isSelected = year == selectedYear;
                      return ListTile(
                        selected: isSelected,
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                semanticLabel: 'Dipilih',
                              )
                            : const Icon(Icons.circle_outlined),
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
                        onTap: () {
                          Navigator.pop(context);
                          onYearSelected(year);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
