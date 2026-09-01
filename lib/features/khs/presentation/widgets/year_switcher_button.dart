import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/widgets/year_picker_sheet.dart';

/// Year switcher button for the KHS app bar.
///
/// Shows the current [tahunAjaran] (e.g., '2024/2025') with a dropdown
/// arrow. Tapping opens a [YearPickerSheet] via [showModalBottomSheet].
///
/// Hidden entirely when [availableYears] is empty.
class YearSwitcherButton extends StatelessWidget {
  const YearSwitcherButton({
    super.key,
    required this.tahunAjaran,
    required this.availableYears,
    required this.onYearSelected,
  });

  /// Current academic year display string, e.g., '2024/2025'.
  final String tahunAjaran;

  /// List of available academic years for selection.
  final List<String> availableYears;

  /// Callback invoked when a year is selected from the picker.
  final ValueChanged<String> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (availableYears.isEmpty) {
      return const SizedBox.shrink();
    }

    return TextButton(
      key: const Key('year_switcher_button'),
      onPressed: () => _showYearPicker(context, cs),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius3XL),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tahunAjaran,
            style: TextStyle(
              fontSize: AppDimens.textSM,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
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
    );
  }

  /// Shows the year picker bottom sheet.
  void _showYearPicker(BuildContext context, ColorScheme cs) {
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
        onYearSelected: (year) {
          Navigator.of(context).pop();
          onYearSelected(year);
        },
      ),
    );
  }
}
