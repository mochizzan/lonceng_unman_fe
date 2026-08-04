// Settings page widgets
// Theme segmented control and reminder settings.
// All strings centralized in AppStrings — no hardcoded text.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';

/// Theme segmented control (Light / Dark / System).
/// Uses [ThemeNotifier] to switch themes at runtime.
class ThemeSegmentedControl extends StatelessWidget {
  const ThemeSegmentedControl({super.key, required this.notifier});

  /// Theme notifier for switching themes.
  final ThemeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SegmentedButton<AppThemeMode>(
      segments: [
        ButtonSegment<AppThemeMode>(
          value: AppThemeMode.light,
          label: Text(AppStrings.settingsThemeLight),
          icon: Icon(Icons.light_mode_outlined, size: 18),
        ),
        ButtonSegment<AppThemeMode>(
          value: AppThemeMode.dark,
          label: Text(AppStrings.settingsThemeDark),
          icon: Icon(Icons.dark_mode_outlined, size: 18),
        ),
        ButtonSegment<AppThemeMode>(
          value: AppThemeMode.system,
          label: Text(AppStrings.settingsThemeSystem),
          icon: Icon(Icons.brightness_auto_outlined, size: 18),
        ),
      ],
      selected: <AppThemeMode>{notifier.currentMode},
      onSelectionChanged: (modes) {
        if (modes.isNotEmpty) {
          notifier.setMode(modes.first);
        }
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: cs.surfaceContainerHighest,
        selectedBackgroundColor: cs.primaryContainer,
        selectedForegroundColor: cs.onPrimaryContainer,
        foregroundColor: cs.onSurfaceVariant,
        textStyle: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// Reminder interval display widget.
/// Shows current reminder interval with chevron for future settings.
class ReminderIntervalTile extends StatelessWidget {
  const ReminderIntervalTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.settingsReminderValue,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
