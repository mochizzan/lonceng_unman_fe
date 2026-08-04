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
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_day_selector.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_timeline.dart';

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

  @override
  void initState() {
    super.initState();
    final state = context.read<JadwalBloc>().state;
    if (state is JadwalLoaded) {
      _selectedDay = state.data.selectedDay;
      _days = state.data.days;
    }
  }

  void _handleDaySelected(String day) {
    setState(() => _selectedDay = day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<JadwalBloc, JadwalState>(
        listener: (context, state) {
          if (state is JadwalLoaded) {
            setState(() {
              _selectedDay = state.data.selectedDay;
              _days = state.data.days;
            });
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, bottom: 32),
        child: Column(
          children: [
            // Day selector pills (horizontal scrollable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: JadwalDaySelector(
                days: _days,
                selectedDay: _selectedDay,
                onDaySelected: _handleDaySelected,
              ),
            ),
            const SizedBox(height: 24),
            // Timeline list — schedule cards
            JadwalTimeline(items: items),
          ],
        ),
      ),
    );
  }
}
