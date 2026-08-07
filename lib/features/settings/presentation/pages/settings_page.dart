// Settings page — theme & reminder controls.
// Accessed from Profile via context.pushNamed(RouteNames.settings).
// Uses ThemeNotifier for runtime theme switching.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/cache/credential_cache.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';
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
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, notifState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notifState.notificationPermissionDenied)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: cs.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.settingsNotificationPermissionDenied,
                              style: TextStyle(
                                color: cs.onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      trailing: ReminderIntervalTile(
                        intervalMinutes: notifState.reminderIntervalMinutes,
                      ),
                      onTap: () {
                        _showReminderIntervalPicker(
                          context,
                          notifState.reminderIntervalMinutes,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimens.space24),

          // ── Section: Account ──
          _SectionHeader(title: AppStrings.settingsSectionAccount),
          const SizedBox(height: AppDimens.space8),
          _SettingsCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: cs.error, size: 22),
              title: Text(
                AppStrings.settingsLogoutButton,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: cs.error),
              ),
              onTap: () => _showLogoutDialog(context),
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

/// Shows a confirmation dialog and triggers logout on confirm.
void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.settingsLogoutConfirmTitle),
      content: const Text(AppStrings.settingsLogoutConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.settingsLogoutCancelAction),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Clear credentials and set auth status to unauthenticated.
            // The router's authRedirect will navigate to /login.
            Services.get<CredentialCache>().clear();
            Services.get<AuthStatusNotifier>().setStatus(
              AuthStatus.unauthenticated,
            );
          },
          child: Text(
            AppStrings.settingsLogoutConfirmAction,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );
}

/// Shows a bottom sheet for selecting the reminder interval.
void _showReminderIntervalPicker(BuildContext context, int currentInterval) {
  final cubit = context.read<NotificationCubit>();

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.settingsReminderLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final minutes in NotificationConfig.reminderOptions)
              ListTile(
                title: Text(
                  minutes >= 60
                      ? AppStrings.settingsReminderHour
                      : AppStrings.settingsReminderMinutes(minutes),
                ),
                trailing: minutes == currentInterval
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  cubit.updateReminderInterval(minutes);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      );
    },
  );
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
