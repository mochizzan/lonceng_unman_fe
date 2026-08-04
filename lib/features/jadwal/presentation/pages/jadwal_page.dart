// jadwal - Jadwal page
//
// Weekly schedule timeline with day selector pills and schedule cards.
// Follows the same BLoC pattern as home's HomePage:
// BlocProvider + BlocBuilder responding to JadwalInitial/JadwalLoading/
// JadwalLoaded/JadwalError states.
// Matches DESIGN.md §5.3 layout.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_event.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_state.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_card.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_day_selector.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key, this.getJadwal});

  /// Optional usecase injection for testing.
  /// When null, a stub implementation is used.
  final GetJadwal? getJadwal;

  static GetJadwal _defaultGetJadwal() {
    return GetJadwal(
      JadwalRepositoryImpl(remoteDataSource: StubJadwalRemoteDataSource()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          JadwalBloc(getJadwal ?? _defaultGetJadwal())
            ..add(const JadwalFetchRequested()),
      child: const _JadwalPageView(),
    );
  }
}

class _JadwalPageView extends StatefulWidget {
  const _JadwalPageView();

  @override
  State<_JadwalPageView> createState() => _JadwalPageViewState();
}

class _JadwalPageViewState extends State<_JadwalPageView> {
  String _selectedDay = '';
  List<String> _days = [];

  void _handleDaySelected(String day) {
    setState(() => _selectedDay = day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<JadwalBloc, JadwalState>(
        builder: (context, state) {
          if (state is JadwalLoading || state is JadwalInitial) {
            return _buildLoading(context);
          }

          if (state is JadwalError) {
            return _buildError(context, state.message);
          }

          if (state is JadwalLoaded) {
            _selectedDay = state.data.selectedDay;
            _days = state.data.days;
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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, JadwalLoaded state) {
    final items = state.data.scheduleItems;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<JadwalBloc>().add(const JadwalRefreshRequested());
      },
      child: CustomScrollView(
        slivers: [
          // 1. App Bar (DESIGN.md §5.3 — title + calendar icon)
          SliverAppBar(
            title: const Text('Jadwal Kuliah'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {},
              ),
            ],
          ),
          // 2. Day selector pills (horizontal scrollable)
          SliverToBoxAdapter(
            child: JadwalDaySelector(
              days: _days,
              selectedDay: _selectedDay,
              onDaySelected: _handleDaySelected,
            ),
          ),
          // 3. Timeline list — schedule cards (same bottom padding as home)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ).copyWith(bottom: 80),
            sliver: items.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Tidak ada jadwal pada hari ini',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => JadwalCard(item: items[index]),
                      childCount: items.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
