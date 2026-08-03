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
import 'package:lonceng_unman_fe/features/home/data/datasources/home_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/home/data/repositories/home_repository_impl.dart';
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

  static GetHome _defaultGetHome() {
    return GetHome(
      HomeRepositoryImpl(remoteDataSource: StubHomeRemoteDataSource()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HomeBloc(getHome ?? _defaultGetHome())
            ..add(const HomeFetchRequested()),
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatelessWidget {
  const _HomePageView();

  String _getDateText() {
    final now = DateTime.now();
    final dayNames = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = dayNames[now.weekday % 7];
    final monthName = monthNames[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
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
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                // Hero countdown card (next class + live timer)
                HeroCountdownCard(
                  nextClass: data.nextClass,
                  countdown: state.countdown,
                ),
                const SizedBox(height: 28),
                // Quick stats (SKS, classes today, semester/IPK)
                QuickStats(data: data),
                const SizedBox(height: 28),
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
