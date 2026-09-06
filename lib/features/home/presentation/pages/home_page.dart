// home - Home page
//
// Main home screen with:
// - Sticky header (date, greeting, notifications, avatar)
// - Hero countdown card (next class + live timer)
// - Quick stats (SKS, classes today, semester/IPK)
// - Today's schedule timeline
//
// Shows skeleton placeholders while loading data from cache.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_refresh_overlay.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_bloc.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_event.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_state.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/hero_countdown_card.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/home_header.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/home_skeleton.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/quick_stats.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/today_schedule.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/shared/widgets/bloc_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomePageView();
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<_HomePageView>
    with WidgetsBindingObserver {
  var _fetchDispatched = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        context.read<HomeBloc>().add(const HomeRefreshRequested());
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selamat datang kembali'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getDateText() {
    final now = DateTime.now();
    final dayName = AppStrings.dayNames[now.weekday - 1];
    final monthName = AppStrings.monthNames[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  void _ensureFetch() {
    if (_fetchDispatched) return;
    _fetchDispatched = true;
    context.read<HomeBloc>().add(const HomeFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    // Initial fetch once; later refreshes come from pull-to-refresh.
    _ensureFetch();

    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          // Prefer real data when already loaded (e.g. stub / cache).
          if (state is HomeLoaded) {
            return _buildContent(context, state);
          }

          if (state is HomeError) {
            return _buildError(context, state.message);
          }

          // Loading → dashboard shell + skeletons.
          return _buildSkeletonDashboard(context);
        },
      ),
    );
  }

  Widget _buildSkeletonDashboard(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: HomeHeader(dateText: '', userName: '…', avatarUrl: ''),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.screenPaddingHorizontal,
          ).copyWith(bottom: AppDimens.space80),
          sliver: const HomeSkeletonSliver(),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return AppErrorDisplay(
      message: message,
      onRetry: () {
        context.read<HomeBloc>().add(const HomeFetchRequested());
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeLoaded state) {
    final data = state.data;
    final notifState = context.watch<NotificationCubit>().state;
    // Dot hanya dari unread visible (deliveredAt <= now && !isRead).
    // Legacy fallback (visibleEmpty && active && !historyViewed) dihapus
    // karena bikin dot selalu merah saat optimistic future / fresh install.
    final hasUnseen = notifState.unreadCount > 0;

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('[HOME] Pull-to-refresh triggered');
        try {
          await DataRefreshOverlay.triggerRefresh(context);
        } catch (e) {
          // Error surfaced by the overlay itself; no extra snackbar here.
          debugPrint('[HOME] Pull-to-refresh error: $e');
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              dateText: _getDateText(),
              userName: data.userName,
              avatarUrl: data.avatarUrl,
              onNotificationTap: () =>
                  context.pushNamed(RouteNames.notificationHistory),
              onAvatarTap: () => context.goNamed(RouteNames.profile),
              hasUnseenNotifications: hasUnseen,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPaddingHorizontal,
            ).copyWith(bottom: AppDimens.space80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimens.space16),
                HeroCountdownCard(nextClass: data.nextClass),
                const SizedBox(height: AppDimens.space28),
                QuickStats(
                  data: data,
                  onKhsTap: () => context.pushNamed(
                    RouteNames.khs,
                    queryParameters: {
                      'tahunAjaran': data.tahunAjaran,
                      'semester': data.semester,
                    },
                  ),
                ),
                const SizedBox(height: AppDimens.space28),
                TodaySchedule(
                  items: data.scheduleItems,
                  onSeeAllTap: () => context.goNamed(RouteNames.jadwal),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
