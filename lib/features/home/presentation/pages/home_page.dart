// home - Home page
//
// Main home screen with:
// - Sticky header (date, greeting, notifications, avatar)
// - Hero countdown card (next class + live timer)
// - Quick stats (SKS, classes today, semester/IPK)
// - Today's schedule timeline
//
// While post-login data initialization runs (background), the layout
// stays visible with skeleton placeholders instead of a full-page spinner.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
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

class _HomePageViewState extends State<_HomePageView> {
  var _fetchDispatched = false;

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
    // Initial fetch once; later refreshes come from DataInitSuccess / pull.
    _ensureFetch();

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          // When background data-init completes, refresh dashboard data.
          BlocListener<DataInitBloc, DataInitBlocState>(
            listenWhen: (prev, next) =>
                next is DataInitSuccess && prev is! DataInitSuccess,
            listener: (context, state) {
              context.read<HomeBloc>().add(const HomeRefreshRequested());
            },
          ),
        ],
        child: BlocBuilder<DataInitBloc, DataInitBlocState>(
          builder: (context, initState) {
            final initInProgress = initState is DataInitInProgress ||
                initState is DataInitIdle;

            return BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                // Prefer real data when already loaded (e.g. stub / cache).
                if (state is HomeLoaded) {
                  return _buildContent(context, state);
                }

                if (state is HomeError && !initInProgress) {
                  return _buildError(context, state.message);
                }

                // Loading or still initializing → dashboard shell + skeletons.
                return _buildSkeletonDashboard(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonDashboard(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: HomeHeader(
            dateText: '',
            userName: '…',
            avatarUrl: '',
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.screenPaddingHorizontal,
          ).copyWith(bottom: AppDimens.space80),
          sliver: HomeSkeletonSliver(),
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
        context.read<HomeBloc>().add(const HomeRefreshRequested());
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
                QuickStats(data: data),
                const SizedBox(height: AppDimens.space28),
                TodaySchedule(items: data.scheduleItems),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
