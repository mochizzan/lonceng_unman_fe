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
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/shared/widgets/data_refresh_overlay.dart';

import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_bloc.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_event.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_state.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/hero_countdown_card.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/home_header.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/home_skeleton.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/quick_stats.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/today_schedule.dart';
import 'package:lonceng_unman_fe/shared/widgets/bloc_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.getHome});

  /// Optional usecase injection for testing.
  /// When null, a stub implementation is used.
  final GetHome? getHome;

  static GetHome _defaultGetHome() => Services.get<GetHome>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: true,
      create: (_) => HomeBloc(getHome ?? _defaultGetHome()),
      child: const _HomePageView(),
    );
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

    return RefreshIndicator(
      onRefresh: () async {
        try {
          // Reset data init state first
          context.read<DataInitBloc>().add(const DataInitReset());

          // Show full-screen overlay
          if (!context.mounted) return;
          DataRefreshOverlay.show(context);

          // Load credentials and start pipeline
          final cache = Services.get<AcademicCacheService>();
          final creds = await cache.loadCredentials();
          if (creds != null && context.mounted) {
            context.read<DataInitBloc>().add(
              DataInitStarted(npm: creds['npm']!, password: creds['password']!),
            );
          }

          // Wait a moment for pipeline to start, then refresh home
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            context.read<HomeBloc>().add(const HomeRefreshRequested());
          }
        } catch (e) {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal memperbarui data'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              dateText: _getDateText(),
              userName: data.userName,
              avatarUrl: data.avatarUrl,
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
                  onKhsTap: () => context.goNamed(
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
