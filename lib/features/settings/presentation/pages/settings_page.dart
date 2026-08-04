// Settings page — theme & reminder controls.
// Accessed from Profile via context.pushNamed(RouteNames.settings).
// Uses ThemeNotifier for runtime theme switching.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/widgets/settings_widgets.dart';

/// Settings page — surfaces theme & reminder controls.
///
/// Requires [themeNotifier] — the same instance used by [MaterialApp]
/// so theme switches reflect globally.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.notifier});

  /// Theme notifier — must be the same instance driving the app theme.
  final ThemeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPaddingHorizontal,
          vertical: AppDimens.screenPaddingVertical,
        ),
        children: [
          // ── Section: Appearance ──
          _SectionHeader(title: AppStrings.settingsSectionAppearance),
          const SizedBox(height: AppDimens.space8),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined, color: cs.onSurface, size: 22),
                    const SizedBox(width: AppDimens.space12),
                    Text(
                      AppStrings.settingsThemeLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space12),
                ThemeSegmentedControl(notifier: notifier),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space24),

          // ── Section: Notifications ──
          _SectionHeader(title: AppStrings.settingsSectionNotification),
          const SizedBox(height: AppDimens.space8),
          _SettingsCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.notifications_outlined,
                color: cs.onSurface,
                size: 22,
              ),
              title: Text(
                AppStrings.settingsReminderLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
              ),
              trailing: const ReminderIntervalTile(),
              onTap: () {
                // TODO: Implement reminder interval picker
              },
            ),
          ),
          const SizedBox(height: AppDimens.space24),

          // ── Section: About ──
          _SectionHeader(title: AppStrings.settingsSectionAbout),
          const SizedBox(height: AppDimens.space8),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.info_outline,
                    color: cs.onSurface,
                    size: 22,
                  ),
                  title: Text(
                    AppStrings.settingsVersionLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                  ),
                  subtitle: Text(
                    '${AppStrings.settingsAppName} ${AppStrings.appVersion}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Card container for settings items with consistent styling.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        child: child,
      ),
    );
  }
}
