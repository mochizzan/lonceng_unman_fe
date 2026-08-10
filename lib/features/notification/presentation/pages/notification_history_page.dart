import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/app_dimens.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

/// Page showing all scheduled notifications with toggle controls.
///
/// Accessible from the bell icon in HomeHeader and Settings.
/// Inherits [NotificationCubit] from ShellRoute's MultiBlocProvider.
class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Mark history as viewed so red dot disappears on home page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationCubit>().markHistoryViewed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notificationHistoryTitle)),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.notifications.isEmpty) {
            return _buildEmptyState(cs);
          }

          return _buildNotificationList(context, state, cs);
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppDimens.space16),
            Text(
              AppStrings.notificationHistoryEmpty,
              style: TextStyle(
                fontSize: AppDimens.textLG,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              AppStrings.notificationHistoryEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    NotificationState state,
    ColorScheme cs,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPaddingHorizontal,
        vertical: AppDimens.space16,
      ),
      itemCount: state.notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space8),
      itemBuilder: (context, index) {
        final notif = state.notifications[index];
        return _NotificationTile(
          notification: notif,
          onToggle: () {
            context.read<NotificationCubit>().toggleNotification(notif.id);
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onToggle});

  final ScheduledNotificationEntity notification;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr =
        '${notification.classTime.hour.toString().padLeft(2, '0')}:'
        '${notification.classTime.minute.toString().padLeft(2, '0')}';

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Row(
          children: [
            // Course info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.courseName,
                    style: TextStyle(
                      fontSize: AppDimens.textBase,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    '${notification.dayOfWeek} • $timeStr • ${notification.room}',
                    style: TextStyle(
                      fontSize: AppDimens.textSM,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (notification.lecturer != null &&
                      notification.lecturer!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.space2),
                    Text(
                      notification.lecturer!,
                      style: TextStyle(
                        fontSize: AppDimens.textXS,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Toggle switch
            Switch(value: notification.isActive, onChanged: (_) => onToggle()),
          ],
        ),
      ),
    );
  }
}
