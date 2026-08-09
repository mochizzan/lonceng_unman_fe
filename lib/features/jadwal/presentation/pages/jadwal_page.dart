// jadwal - Jadwal page
//
// Weekly schedule timeline with day selector pills and schedule cards.
// Follows the same BLoC pattern as home's HomePage:
// BlocProvider + BlocBuilder responding to JadwalInitial/JadwalLoading/
// JadwalLoaded/JadwalError states.
// Matches DESIGN.md §5.3 layout.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_event.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_state.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_day_selector.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_timeline.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/shared/widgets/bloc_scaffold.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _JadwalPageView();
  }
}

class _JadwalPageView extends StatefulWidget {
  const _JadwalPageView();

  @override
  State<_JadwalPageView> createState() => _JadwalPageViewState();
}

class _JadwalPageViewState extends State<_JadwalPageView> {
  @override
  void initState() {
    super.initState();
    // Only fetch if we don't already have loaded data.
    // This prevents redundant API calls when switching tabs.
    final state = context.read<JadwalBloc>().state;
    if (state is! JadwalLoaded) {
      context.read<JadwalBloc>().add(const JadwalFetchRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<JadwalBloc, JadwalState>(
        listener: (context, state) {
          if (state is JadwalLoaded) {
            context.read<NotificationCubit>().scheduleFromJadwal(state.data);
          }
        },
        child: BlocBuilder<JadwalBloc, JadwalState>(
          builder: (context, state) {
            if (state is JadwalLoading || state is JadwalInitial) {
              return _buildLoading(context);
            }

            if (state is JadwalError) {
              return _buildError(context, state.message);
            }

            if (state is JadwalLoaded) {
              return _buildContent(context, state);
            }

            return _buildLoading(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const _JadwalSkeleton();
  }

  Widget _buildError(BuildContext context, String message) {
    return AppErrorDisplay(message: message);
  }

  Widget _buildContent(BuildContext context, JadwalLoaded state) {
    final items = state.data.scheduleItems;

    return RefreshIndicator(
      onRefresh: () async {
        final academicCache = Services.get<AcademicCacheService>();
        final credentials = await academicCache.loadCredentials();
        if (credentials == null || !context.mounted) return;

        final npm = credentials['npm'] ?? '';
        final password = credentials['password'] ?? '';

        context.read<DataInitBloc>().add(const DataInitReset());
        context.read<DataInitBloc>().add(
          DataInitStarted(npm: npm, password: password, forceRefresh: true),
        );

        context.read<JadwalBloc>().add(const JadwalRefreshRequested());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: AppDimens.space40,
          bottom: AppDimens.space80,
        ),
        child: Column(
          children: [
            // Day selector pills (horizontal scrollable)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space24,
              ),
              child: JadwalDaySelector(
                days: state.days,
                selectedDay: state.selectedDay,
                onDaySelected: (day) {
                  context.read<JadwalBloc>().add(JadwalDaySelected(day));
                },
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            // Timeline list — schedule cards
            JadwalTimeline(items: items, selectedDay: state.selectedDay),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton placeholder matching JadwalPage layout
// ---------------------------------------------------------------------------

class _JadwalSkeleton extends StatelessWidget {
  const _JadwalSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shimmerColor = cs.surfaceContainerHighest.withValues(alpha: 0.7);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppDimens.space24,
        bottom: AppDimens.space32,
      ),
      child: Column(
        children: [
          // Day selector pill skeleton — row of rounded pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 7,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space20,
                  vertical: AppDimens.space8,
                ),
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppDimens.space10),
                itemBuilder: (_, _) => Container(
                  width: 48,
                  height: 40,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space24),
          // Timeline skeleton — 4 items: dot + line + card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
            child: Column(
              children: List.generate(4, (index) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dot column
                      SizedBox(
                        width: 24,
                        child: Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (index < 3)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimens.space16),
                      // Card skeleton
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimens.space16,
                          ),
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusMD,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
