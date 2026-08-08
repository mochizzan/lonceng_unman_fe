// Settings page widgets
// Theme segmented control and reminder settings.
// All strings centralized in AppStrings — no hardcoded text.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';

/// Theme segmented control (Light / Dark / System).
/// Uses [ThemeNotifier] to switch themes at runtime.
///
/// Listens to [ThemeNotifier] via [ListenableBuilder] — no StatefulWidget needed.
class ThemeSegmentedControl extends StatelessWidget {
  const ThemeSegmentedControl({super.key, required this.notifier});

  /// Theme notifier for switching themes.
  final ThemeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;

        return SegmentedButton<AppThemeMode>(
          segments: [
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.light,
              label: Text(AppStrings.settingsThemeLight),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.dark,
              label: Text(AppStrings.settingsThemeDark),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.system,
              label: Text(AppStrings.settingsThemeSystem),
            ),
          ],
          selected: {notifier.currentMode},
          onSelectionChanged: (modes) {
            if (modes.isNotEmpty) {
              notifier.setMode(modes.first);
            }
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return cs.primaryContainer;
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return cs.onPrimaryContainer;
              }
              return cs.onSurface;
            }),
            side: WidgetStateProperty.all(
              BorderSide(color: cs.outline, width: 1),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          showSelectedIcon: false,
        );
      },
    );
  }
}

/// Reminder interval display widget.
/// Shows current reminder interval with chevron for settings.
class ReminderIntervalTile extends StatelessWidget {
  const ReminderIntervalTile({super.key, required this.intervalMinutes});

  /// Current reminder interval in minutes (from NotificationCubit state).
  final int intervalMinutes;

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
            _formatInterval(intervalMinutes),
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

  String _formatInterval(int minutes) {
    if (minutes >= 60) return AppStrings.settingsReminderHour;
    return AppStrings.settingsReminderMinutes(minutes);
  }
}
