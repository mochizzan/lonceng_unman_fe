// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/khs_timeline_view.dart';

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

  @override
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
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

Future<_FakeDataInitBloc> _pumpView(
  WidgetTester tester, {
  ValueChanged<int>? onKhsCountChanged,
}) async {
  final bloc = _FakeDataInitBloc();
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<DataInitBloc>.value(
        value: bloc,
        child: DataInitProgressView(
          isFreshLogin: false,
          onKhsCountChanged: onKhsCountChanged,
        ),
      ),
    ),
  );
  return bloc;
}

void main() {
  testWidgets('heavy path: accumulates two semesters and finalizes previous', (
    tester,
  ) async {
    int lastCount = -1;
    final bloc = await _pumpView(
      tester,
      onKhsCountChanged: (c) => lastCount = c,
    );

    // Fresh start clears.
    bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
    await tester.pump();

    // Semester A: download → extract → fetch
    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.downloadingKhs,
        detail: '2022/2023 Ganjil',
      ),
    );
    await tester.pump();
    expect(lastCount, 1);
    expect(find.text('2022/2023 — Ganjil'), findsOneWidget);
    // Download chip is pulsing (FadeTransition present for progress).
    expect(find.byType(FadeTransition), findsWidgets);

    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.extractingKhs,
        detail: '2022/2023 Ganjil',
      ),
    );
    await tester.pump();
    expect(find.text('2022/2023 — Ganjil'), findsOneWidget);

    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.fetchingKhsData,
        detail: '2022/2023 Ganjil',
      ),
    );
    await tester.pump();
    expect(find.text('2022/2023 — Ganjil'), findsOneWidget);

    // Semester B starts — previous semester's fetch should auto-success,
    // and new semester appears.
    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.downloadingKhs,
        detail: '2022/2023 Genap',
      ),
    );
    await tester.pump();
    expect(lastCount, 2);
    expect(find.text('2022/2023 — Ganjil'), findsOneWidget);
    expect(find.text('2022/2023 — Genap'), findsOneWidget);
  });

  testWidgets('light path: skipping download/extract shows Dilewati', (
    tester,
  ) async {
    final bloc = await _pumpView(tester);

    bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
    await tester.pump();

    // Light/debounced path — only fetchingKhsData per semester.
    bloc.emitNow(const DataInitInProgress(DataInitStatus.fetchingKhsSemesters));
    await tester.pump();

    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.fetchingKhsData,
        detail: '2023/2024 Ganjil',
      ),
    );
    await tester.pump();
    expect(find.text('2023/2024 — Ganjil'), findsOneWidget);
    // Download/extract were idle → marked skipped → Dilewati.
    expect(find.text('Dilewati'), findsNWidgets(2));

    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.fetchingKhsData,
        detail: '2023/2024 Genap',
      ),
    );
    await tester.pump();
    expect(find.text('2023/2024 — Genap'), findsOneWidget);
    // Two semesters × 2 Dilewati each = 4
    expect(find.text('Dilewati'), findsNWidgets(4));
  });

  testWidgets('DataInitIdle clears accumulator', (tester) async {
    final bloc = await _pumpView(tester);

    bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
    await tester.pump();
    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.downloadingKhs,
        detail: '2022/2023 Ganjil',
      ),
    );
    await tester.pump();
    expect(find.text('2022/2023 — Ganjil'), findsOneWidget);

    bloc.emitNow(const DataInitIdle());
    await tester.pump();
    expect(find.text('2022/2023 — Ganjil'), findsNothing);
    expect(find.byType(KhsTimelineView), findsNothing);
  });

  testWidgets('null detail is ignored and does not create an entry', (
    tester,
  ) async {
    int lastCount = -1;
    final bloc = await _pumpView(
      tester,
      onKhsCountChanged: (c) => lastCount = c,
    );

    bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
    await tester.pump();

    bloc.emitNow(const DataInitInProgress(DataInitStatus.downloadingKhs));
    await tester.pump();
    // No detail → ignored.
    expect(lastCount, 0);
    expect(find.byType(KhsTimelineView), findsNothing);

    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.downloadingKhs,
        detail: 'Ganjil', // no space → parse null → ignored.
      ),
    );
    await tester.pump();
    expect(lastCount, 0);
    expect(find.byType(KhsTimelineView), findsNothing);
  });

  testWidgets('DataInitSuccess finalizes all progress sub-steps', (
    tester,
  ) async {
    final bloc = await _pumpView(tester);

    bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
    await tester.pump();
    bloc.emitNow(
      const DataInitInProgress(
        DataInitStatus.downloadingKhs,
        detail: '2022/2023 Ganjil',
      ),
    );
    await tester.pump();
    // Still progress — FadeTransition present.
    expect(find.byType(FadeTransition), findsWidgets);

    bloc.emitNow(const DataInitSuccess());
    await tester.pump();
    // After success, progress → success, no more pulsing.
    // Timeline still visible as context.
    expect(find.text('2022/2023 — Ganjil'), findsOneWidget);
  });
}
