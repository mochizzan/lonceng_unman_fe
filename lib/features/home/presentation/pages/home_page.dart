// home - Home page
//
// Main home screen with:
// - Sticky header (date, greeting, notifications, avatar)
// - Hero countdown card (next class + live timer)
// - Quick stats (SKS, classes today, semester/IPK)
// - Today's schedule timeline
// Follows Clean Architecture: UI depends on BLoC state.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_bloc.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_event.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_state.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/hero_countdown_card.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/home_header.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/quick_stats.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/today_schedule.dart';

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

class _HomePageView extends StatelessWidget {
  const _HomePageView();

  String _getDateText() {
    final now = DateTime.now();
    final dayNames = [
      AppStrings.daySunday,
      AppStrings.dayMonday,
      AppStrings.dayTuesday,
      AppStrings.dayWednesday,
      AppStrings.dayThursday,
      AppStrings.dayFriday,
      AppStrings.daySaturday,
    ];
    final monthNames = [
      AppStrings.monthJanuary,
      AppStrings.monthFebruary,
      AppStrings.monthMarch,
      AppStrings.monthApril,
      AppStrings.monthMay,
      AppStrings.monthJune,
      AppStrings.monthJuly,
      AppStrings.monthAugust,
      AppStrings.monthSeptember,
      AppStrings.monthOctober,
      AppStrings.monthNovember,
      AppStrings.monthDecember,
    ];
    final dayName = dayNames[now.weekday % 7];
    final monthName = monthNames[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Dispatch initial fetch when this widget first builds.
    // The BLoC is lazy — it was not created in BlocProvider.create.
    context.read<HomeBloc>().add(const HomeFetchRequested());

    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return _buildLoading(context);
          }

          if (state is HomeError) {
            return _buildError(context, state.message);
          }

          if (state is HomeLoaded) {
            return _buildContent(context, state);
          }

          return _buildLoading(context);
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimens.iconError,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppDimens.space16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
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
          // Header (top app bar with date, greeting, notification, avatar)
          SliverToBoxAdapter(
            child: HomeHeader(
              dateText: _getDateText(),
              userName: data.userName,
              avatarUrl: data.avatarUrl,
            ),
          ),
          // Main content
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPaddingHorizontal,
            ).copyWith(bottom: AppDimens.space80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimens.space16),
                // Hero countdown card (next class + live timer)
                HeroCountdownCard(nextClass: data.nextClass),
                const SizedBox(height: AppDimens.space28),
                // Quick stats (SKS, classes today, semester/IPK)
                QuickStats(data: data),
                const SizedBox(height: AppDimens.space28),
                // Today's schedule timeline
                TodaySchedule(items: data.scheduleItems),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
