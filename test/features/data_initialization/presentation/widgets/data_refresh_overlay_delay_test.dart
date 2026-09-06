// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_refresh_overlay.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({bool isOnline = true}) : _isOnline = isOnline;
  bool _isOnline;
  final _controller = StreamController<bool>.broadcast();
  @override
  bool get isOnline => _isOnline;
  @override
  Stream<bool> get onStatusChange => _controller.stream;
  @override
  Future<void> refresh() async {}
}

final _fakeConnectivity = _FakeConnectivityService(isOnline: true);

class _NoOpRepo implements DataInitializationRepository {
  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) => const Stream<DataInitProgress>.empty();
}

class _FakeDataInitBloc extends DataInitBloc {
  _FakeDataInitBloc()
    : super(
        GetDataInitialization(_NoOpRepo()),
        connectivity: _fakeConnectivity,
      );
  void emitNow(DataInitBlocState state) => emit(state);
}

Future<_FakeDataInitBloc> _pumpOverlay(WidgetTester tester) async {
  final bloc = _FakeDataInitBloc();
  addTearDown(bloc.close);
  bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<DataInitBloc>.value(
        value: bloc,
        child: const DataRefreshOverlay(),
      ),
    ),
  );
  return bloc;
}

void main() {
  testWidgets(
    'success with >1 semester holds overlay 1.5s before pop (khsCount > 1)',
    (tester) async {
      final bloc = await _pumpOverlay(tester);

      // Build two KHS semesters via progress view accumulator.
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.downloadingKhs,
          detail: '2022/2023 Ganjil',
        ),
      );
      await tester.pump();
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.fetchingKhsData,
          detail: '2022/2023 Ganjil',
        ),
      );
      await tester.pump();
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.downloadingKhs,
          detail: '2022/2023 Genap',
        ),
      );
      await tester.pump();
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.fetchingKhsData,
          detail: '2022/2023 Genap',
        ),
      );
      await tester.pump();

      // Two semesters accumulated — now succeed.
      bloc.emitNow(const DataInitSuccess());
      await tester.pump();

      // After 800ms (past 500ms but before 1500ms) overlay still visible.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(
        find.byType(DataInitProgressView),
        findsOneWidget,
        reason: 'With >1 semester, overlay should hold 1.5s, not 500ms.',
      );

      // After 1.5s total, overlay gone.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(
        find.byType(DataInitProgressView),
        findsNothing,
        reason: 'Overlay should auto-close after 1.5s for >1 semester.',
      );
    },
  );

  testWidgets('success with 0/1 semester dismisses in 500ms (fast path)', (
    tester,
  ) async {
    final bloc = await _pumpOverlay(tester);
    // No KHS semesters accumulated.
    bloc.emitNow(const DataInitSuccess());
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(
      find.byType(DataInitProgressView),
      findsNothing,
      reason: 'With 0 semesters, overlay should dismiss in 500ms.',
    );
  });
}
