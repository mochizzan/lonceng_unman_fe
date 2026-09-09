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
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/khs_timeline_view.dart';

class _FakeCS implements ConnectivityService {
  _FakeCS({bool isOnline = true}) : _isOnline = isOnline;
  bool _isOnline;
  final _c = StreamController<bool>.broadcast();
  @override
  bool get isOnline => _isOnline;
  @override
  Stream<bool> get onStatusChange => _c.stream;
  @override
  Future<void> refresh() async {}
}

final _cs = _FakeCS(isOnline: true);

class _NoOpRepo implements DataInitializationRepository {
  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) => const Stream.empty();

  @override
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  }) => const Stream.empty();
}

class _FakeBloc extends DataInitBloc {
  _FakeBloc() : super(GetDataInitialization(_NoOpRepo()), connectivity: _cs);
  void emitNow(DataInitBlocState s) => emit(s);
}

Future<_FakeBloc> _pump(WidgetTester t) async {
  final b = _FakeBloc();
  addTearDown(b.close);
  await t.pumpWidget(
    MaterialApp(
      home: BlocProvider<DataInitBloc>.value(
        value: b,
        child: const DataInitProgressView(isFreshLogin: false),
      ),
    ),
  );
  return b;
}

void main() {
  group('KHS per-semester error sentinel', () {
    testWidgets(
      '2024/2025 download error -> badge merah, survive pipeline + finalize tidak jadi hijau',
      (tester) async {
        final bloc = await _pump(tester);
        bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
        await tester.pump();
        bloc.emitNow(
          const DataInitInProgress(
            DataInitStatus.downloadingKhs,
            detail: '2022/2023 Ganjil',
          ),
        );
        await tester.pump();
        bloc.emitNow(
          const DataInitInProgress(
            DataInitStatus.extractingKhs,
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
        // 2024/2025 fail at download - sentinel
        bloc.emitNow(
          const DataInitInProgress(
            DataInitStatus.downloadingKhs,
            detail: '2024/2025 Ganjil',
          ),
        );
        await tester.pump();
        bloc.emitNow(
          const DataInitInProgress(
            DataInitStatus.downloadingKhs,
            detail: '2024/2025 Ganjil ::error::download',
          ),
        );
        await tester.pump();
        // Next semester continues
        bloc.emitNow(
          const DataInitInProgress(
            DataInitStatus.downloadingKhs,
            detail: '2025/2026 Ganjil',
          ),
        );
        await tester.pump();
        bloc.emitNow(
          const DataInitInProgress(
            DataInitStatus.fetchingKhsData,
            detail: '2025/2026 Ganjil',
          ),
        );
        await tester.pump();
        await tester.pump();
        // After next semester finalize, failed semester still error not success
        expect(find.text('2024/2025 — Ganjil'), findsOneWidget);
        // Badge for failed download should be errorContainer (merah): find error icon inside that row
        expect(
          find.byIcon(Icons.error),
          findsWidgets,
          reason: 'failed download must show error icon (merah)',
        );
        // Overall semester dot should be error (cs.error) not success
      },
    );

    testWidgets('light path fetch error sentinel -> GET merah', (tester) async {
      final bloc = await _pump(tester);
      bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
      await tester.pump();
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.fetchingKhsData,
          detail: '2024/2025 Ganjil',
        ),
      );
      await tester.pump();
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.fetchingKhsData,
          detail: '2024/2025 Ganjil ::error::fetch',
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('2024/2025 — Ganjil'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsWidgets);
    });

    testWidgets('_finalizeAllProgress must preserve error (not jadi hijau)', (
      tester,
    ) async {
      final bloc = await _pump(tester);
      bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
      await tester.pump();
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.downloadingKhs,
          detail: '2024/2025 Ganjil',
        ),
      );
      await tester.pump();
      bloc.emitNow(
        const DataInitInProgress(
          DataInitStatus.downloadingKhs,
          detail: '2024/2025 Ganjil ::error::download',
        ),
      );
      await tester.pump();
      bloc.emitNow(const DataInitSuccess());
      await tester.pump();
      expect(find.text('2024/2025 — Ganjil'), findsOneWidget);
      // Still error after DataInitSuccess finalize
      expect(
        find.byIcon(Icons.error),
        findsWidgets,
        reason: 'finalizeAll must not overwrite error -> success',
      );
    });
  });
}
