import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/widgets/year_picker_sheet.dart';

/// Tappable AppBar title for KHS detail page.
///
/// Renders `KHS 2024/2025 ▾` (format A) with full-title hit area.
/// Tap always opens [YearPickerSheet] — even when [availableYears] is empty
/// (B), showing empty state `Belum ada tahun ajaran` in the sheet.
///
/// Replaces the former `YearSwitcherButton` that lived in `AppBar.actions`.
class KhsAppBarTitle extends StatelessWidget {
  const KhsAppBarTitle({
    super.key,
    required this.tahunAjaran,
    required this.availableYears,
    required this.onYearSelected,
    this.isFetching = false,
  });

  /// Current academic year, e.g. `2024/2025`.
  final String tahunAjaran;

  /// All available years from cache.
  final List<String> availableYears;

  /// Called when a year is picked in the sheet.
  final ValueChanged<String> onYearSelected;

  /// Whether a manual fetch is in progress (kept for future guard; currently
  /// title remains enabled even while fetching — see §4.3).
  final bool isFetching;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showSheet(context),
      borderRadius: BorderRadius.circular(AppDimens.radius3XL),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space4,
          vertical: AppDimens.space4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.khsTitle} $tahunAjaran',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppDimens.space4),
            Icon(
              Icons.arrow_drop_down,
              size: AppDimens.iconSM,
              color: cs.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLG),
        ),
      ),
      builder: (context) => YearPickerSheet(
        years: availableYears,
        selectedYear: tahunAjaran,
        onYearSelected: onYearSelected,
      ),
    );
  }
}
