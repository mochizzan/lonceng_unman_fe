import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/app_dimens.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

/// Real notification history: delivered (classReminder + FCM) timeline.
///
/// Grouped by Hari ini / Kemarin / Minggu ini / Lebih lama, newest first.
/// Future optimistic items (deliveredAt > now) hidden via visibleDelivered.
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = context.read<NotificationCubit>();
      await cubit.loadDelivered();
      if (!mounted) return;
      await cubit.markAllRead();
    });
  }

  String _groupLabel(DateTime deliveredAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deliveredDay = DateTime(
      deliveredAt.year,
      deliveredAt.month,
      deliveredAt.day,
    );
    final diff = today.difference(deliveredDay).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return 'Minggu ini';
    return 'Lebih lama';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${AppStrings.monthNames[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('notification_history_page'),
      appBar: AppBar(
        title: const Text(AppStrings.notificationHistoryTitle),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final hasVisible = state.visibleDelivered.isNotEmpty;
              return IconButton(
                key: const Key('delete_all_delivered'),
                tooltip: 'Hapus semua',
                onPressed: hasVisible
                    ? () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus semua?'),
                            content: const Text(
                              'Semua riwayat notifikasi akan dihapus.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await context
                              .read<NotificationCubit>()
                              .deleteAllDelivered();
                        }
                      }
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == NotificationStatus.error) {
            return _buildErrorState(
              state.errorMessage ?? 'Gagal memuat riwayat',
              cs,
            );
          }

          final visible = state.visibleDelivered;
          if (visible.isEmpty) {
            return _buildEmptyState(cs);
          }

          return _buildDeliveredList(context, visible, cs);
        },
      ),
    );
  }

  Widget _buildErrorState(String msg, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.error),
            const SizedBox(height: AppDimens.space16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimens.textLG,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            ElevatedButton(
              onPressed: () =>
                  context.read<NotificationCubit>().loadDelivered(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
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

  Widget _buildDeliveredList(
    BuildContext context,
    List<NotificationDeliveredEntity> visible,
    ColorScheme cs,
  ) {
    // Build grouped list: header + tiles
    final widgets = <Widget>[];
    String? lastGroup;
    for (final d in visible) {
      final group = _groupLabel(d.deliveredAt);
      if (group != lastGroup) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPaddingHorizontal,
              AppDimens.space16,
              AppDimens.screenPaddingHorizontal,
              AppDimens.space8,
            ),
            child: Text(
              group,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        );
        lastGroup = group;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.screenPaddingHorizontal,
            vertical: AppDimens.space4,
          ),
          child: Dismissible(
            key: ValueKey('delivered_${d.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppDimens.space16),
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              ),
              child: Icon(Icons.delete, color: cs.onError),
            ),
            onDismissed: (_) {
              context.read<NotificationCubit>().deleteDelivered(d.id);
            },
            child: _DeliveredTile(
              entity: d,
              formatTime: _formatTime,
              formatDate: _formatDate,
              onTap: () {
                if (!d.isRead) {
                  context.read<NotificationCubit>().markAsRead(d.id);
                }
              },
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimens.space16),
      itemCount: widgets.length,
      itemBuilder: (ctx, i) => widgets[i],
    );
  }
}

class _DeliveredTile extends StatelessWidget {
  const _DeliveredTile({
    required this.entity,
    required this.formatTime,
    required this.formatDate,
    required this.onTap,
  });

  final NotificationDeliveredEntity entity;
  final String Function(DateTime) formatTime;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFcm = entity.source == NotificationSource.fcm;
    final title = isFcm
        ? (entity.title ?? entity.courseName)
        : entity.courseName;
    final subtitle = isFcm
        ? (entity.body ?? '')
        : '${entity.dayOfWeek} • ${formatTime(entity.classTime)} • ${entity.room}';
    final timeLabel =
        '${formatDate(entity.deliveredAt)} • ${formatTime(entity.deliveredAt)}';

    return Material(
      key: Key('delivered_tile_${entity.id}'),
      color: entity.isRead
          ? cs.surfaceContainerHighest
          : cs.surfaceContainerHighest.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isFcm ? cs.secondaryContainer : cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFcm ? Icons.notifications : Icons.school,
                  size: 20,
                  color: isFcm
                      ? cs.onSecondaryContainer
                      : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: AppDimens.textBase,
                              fontWeight: entity.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (!entity.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: cs.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppDimens.textSM,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.space2),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: AppDimens.textXS,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
