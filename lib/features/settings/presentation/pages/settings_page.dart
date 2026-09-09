// Settings page — theme & reminder controls.
// Accessed from Profile via context.pushNamed(RouteNames.settings).
// Uses ThemeNotifier for runtime theme switching.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_refresh_overlay.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/services/pipeline_notification_seeder.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/widgets/settings_widgets.dart';

/// Settings page — surfaces theme & reminder controls.
///
/// Requires [themeNotifier] — the same instance used by [MaterialApp]
/// so theme switches reflect globally.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.notifier});

  /// Theme notifier — must be the same instance driving the app theme.
  final ThemeNotifier notifier;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<Map<String, dynamic>?> _krsFuture;
  bool _didLoadNotifications = false;

  @override
  void initState() {
    super.initState();
    _krsFuture = _loadKrsFuture();
  }

  Future<Map<String, dynamic>?> _loadKrsFuture() async {
    try {
      final cache = Services.get<AcademicCacheService>();
      final creds = await cache.loadCredentials();
      final npm = creds?['npm'];
      if (npm == null || npm.isEmpty) return null;
      return cache.loadKrsData(npm: npm);
    } catch (_) {
      return null;
    }
  }

  void _refreshKrsFuture() {
    setState(() {
      _krsFuture = _loadKrsFuture();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadNotifications) {
      _didLoadNotifications = true;
      // Auto-refresh notifications when page becomes visible (covers cold-start
      // where root guard already seeded but cubit state not yet loaded).
      Future.microtask(() {
        if (!mounted) return;
        try {
          context.read<NotificationCubit>().loadNotifications();
        } catch (_) {}
      });
    }
  }

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
                ThemeSegmentedControl(notifier: widget.notifier),
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
                  const SizedBox(height: AppDimens.space8),
                  _SettingsCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.history,
                        color: cs.onSurface,
                        size: 22,
                      ),
                      title: Text(
                        AppStrings.notificationHistoryTitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                        size: 22,
                      ),
                      onTap: () =>
                          context.pushNamed(RouteNames.notificationHistory),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Notification toggle per class ──
          const SizedBox(height: AppDimens.space16),
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, notifState) {
              if (notifState.notifications.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: AppStrings.settingsNotificationClasses,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    _SettingsCard(
                      child: Column(
                        children: notifState.notifications.map((notif) {
                          return _NotificationToggleTile(
                            notification: notif,
                            onToggle: () => context
                                .read<NotificationCubit>()
                                .toggleNotification(notif.id),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }
              // Empty → distinguish KRS empty vs seeding pending via cached Future
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: AppStrings.settingsNotificationClasses),
                  const SizedBox(height: AppDimens.space8),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _krsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const _SeedingLoadingCard();
                      }
                      final krsJson = snap.data;
                      final isKrsEmpty = _isKrsEmpty(krsJson);
                      if (isKrsEmpty) {
                        return _KrsEmptyCard(
                          onReload: () async {
                            _refreshKrsFuture();
                            try {
                              final bloc = context.read<DataInitBloc>();
                              final st = bloc.state;
                              if (st is DataInitPaused ||
                                  st is DataInitFailure) {
                                bloc.add(const DataInitRetry());
                              } else {
                                await DataRefreshOverlay.triggerRefresh(
                                  context,
                                );
                              }
                            } catch (_) {
                              // DataInitBloc not in tree (e.g., in test) — fallback to seeder
                              try {
                                await Services.get<PipelineNotificationSeeder>()
                                    .seedFromCache();
                              } catch (_) {}
                            }
                            if (context.mounted) {
                              try {
                                await context
                                    .read<NotificationCubit>()
                                    .loadNotifications();
                              } catch (_) {}
                            }
                          },
                          onOpenJadwal: () =>
                              context.go('/${RouteNames.jadwal}'),
                        );
                      }
                      // KRS exists but notifications empty → seeding pending
                      return _SeedingEmptyCard(
                        onReload: () async {
                          try {
                            await Services.get<PipelineNotificationSeeder>()
                                .seedFromCache();
                          } catch (_) {}
                          if (context.mounted) {
                            try {
                              await context
                                  .read<NotificationCubit>()
                                  .loadNotifications();
                            } catch (_) {}
                            _refreshKrsFuture();
                          }
                        },
                      );
                    },
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

  bool _isKrsEmpty(Map<String, dynamic>? krsJson) {
    if (krsJson == null) return true;
    // Try typed parse via KrsModel first (handles both snake/camel)
    try {
      final parsed = KrsModel.fromJson(krsJson);
      return parsed.krs.mataKuliah.isEmpty;
    } catch (_) {}
    // Fallback raw check
    final krsOuter = krsJson['krs'];
    if (krsOuter is Map) {
      final raw =
          (krsOuter['mata_kuliah'] as List?) ??
          (krsOuter['mataKuliah'] as List?) ??
          (krsOuter['mata_kuliah'] as List?);
      if (raw != null) return raw.isEmpty;
      // Also try outer directly (krsJson might be inner KrsData)
      final outerList =
          (krsOuter['mata_kuliah'] as List?) ??
          (krsOuter['mataKuliah'] as List?);
      if (outerList != null) return outerList.isEmpty;
      return true;
    }
    final direct =
        (krsJson['mata_kuliah'] as List?) ?? (krsJson['mataKuliah'] as List?);
    if (direct != null) return direct.isEmpty;
    return true;
  }
}

/// Shows a confirmation dialog and triggers logout on confirm.
void _showLogoutDialog(BuildContext context) {
  debugPrint('[SETTINGS] _showLogoutDialog() START');
  debugPrint('[SETTINGS] Logout dialog shown');
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
          onPressed: () async {
            debugPrint('[SETTINGS] User confirmed logout');
            Navigator.of(context).pop();
            debugPrint('[SETTINGS] Calling performFullLogout...');
            await Services.performFullLogout();
            debugPrint('[SETTINGS] Logout OK');
          },
          child: Text(
            AppStrings.settingsLogoutConfirmAction,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );
  debugPrint('[SETTINGS] _showLogoutDialog() END');
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

/// Toggle tile for a single notification in settings.
class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.notification,
    required this.onToggle,
  });

  final ScheduledNotificationEntity notification;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr =
        '${notification.classTime.hour.toString().padLeft(2, '0')}:'
        '${notification.classTime.minute.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        notification.isActive
            ? Icons.notifications_active
            : Icons.notifications_off,
        color: notification.isActive ? cs.primary : cs.onSurfaceVariant,
        size: 22,
      ),
      title: Text(
        notification.courseName,
        style: TextStyle(
          fontSize: AppDimens.textBase,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
      subtitle: Text(
        '${notification.dayOfWeek} • $timeStr • ${notification.room}',
        style: TextStyle(
          fontSize: AppDimens.textSM,
          color: cs.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: notification.isActive,
        onChanged: (_) => onToggle(),
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

class _KrsEmptyCard extends StatelessWidget {
  const _KrsEmptyCard({required this.onReload, required this.onOpenJadwal});
  final VoidCallback onReload;
  final VoidCallback onOpenJadwal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SettingsCard(
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            'Belum ada jadwal kuliah',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'KRS dari backend kosong — tarik untuk memuat ulang atau coba lagi',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onReload,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Muat Ulang'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenJadwal,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Buka Jadwal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeedingEmptyCard extends StatelessWidget {
  const _SeedingEmptyCard({required this.onReload});
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SettingsCard(
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Memuat pengingat...',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Jadwal tersedia, menyiapkan notifikasi',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _SeedingLoadingCard extends StatelessWidget {
  const _SeedingLoadingCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SettingsCard(
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(height: 8),
          Text('Memuat...', style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
