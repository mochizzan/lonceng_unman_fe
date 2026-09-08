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

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({bool isOnline = true}) : _isOnline = isOnline;
  bool _isOnline;
  final _c = StreamController<bool>.broadcast();
  @override
  bool get isOnline => _isOnline;
  @override
  Stream<bool> get onStatusChange => _c.stream;
  @override
  Future<void> refresh() async {}
}

final _fakeConnectivity = _FakeConnectivity(isOnline: true);

class _NoOpRepo implements DataInitializationRepository {
  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) => const Stream.empty();
}

class _FakeBloc extends DataInitBloc {
  _FakeBloc()
    : super(
        GetDataInitialization(_NoOpRepo()),
        connectivity: _fakeConnectivity,
      );
  void emitNow(DataInitBlocState s) => emit(s);
}

Future<_FakeBloc> _pumpView(
  WidgetTester tester, {
  required DataInitBlocState initial,
  VoidCallback? onRetry,
  VoidCallback? onSkip,
  VoidCallback? onCancel,
  VoidCallback? onClose,
}) async {
  final bloc = _FakeBloc();
  addTearDown(bloc.close);
  bloc.emitNow(initial);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider<DataInitBloc>.value(
          value: bloc,
          child: DataInitProgressView(
            isFreshLogin: true,
            onRetry: onRetry,
            onSkip: onSkip,
            onCancel: onCancel,
            onClose: onClose,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

void main() {
  testWidgets('Paused profile → Retry + Back to Login, no Skip', (
    tester,
  ) async {
    await _pumpView(
      tester,
      initial: const DataInitPaused(
        'offline',
        failedStep: 'profile_get',
        skippable: false,
      ),
      onRetry: () {},
      onSkip: () {},
      onCancel: () {},
    );
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(find.text('Kembali ke Login'), findsOneWidget);
    expect(find.text('Lewati'), findsNothing);
  });

  testWidgets('Paused krs_download → Retry + Lewati, no Back', (tester) async {
    await _pumpView(
      tester,
      initial: const DataInitPaused(
        'offline',
        failedStep: 'krs_download',
        skippable: true,
      ),
      onRetry: () {},
      onSkip: () {},
      onCancel: () {},
    );
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Kembali ke Login'), findsNothing);
  });

  testWidgets('Paused khs_download skippable shows Lewati', (tester) async {
    await _pumpView(
      tester,
      initial: const DataInitPaused(
        'offline',
        failedStep: 'khs_download_Ganjil',
        skippable: true,
      ),
      onRetry: () {},
      onSkip: () {},
    );
    expect(find.text('Lewati'), findsOneWidget);
  });

  testWidgets('Failure non-network shows no Lewati', (tester) async {
    await _pumpView(
      tester,
      initial: const DataInitFailure('err', failedStep: 'krs_download'),
      onRetry: () {},
      onSkip: () {},
      onClose: () {},
    );
    expect(find.text('Lewati'), findsNothing);
  });

  testWidgets('Paused network hint text', (tester) async {
    await _pumpView(
      tester,
      initial: const DataInitPaused(
        'offline',
        failedStep: 'krs_download',
        skippable: true,
      ),
      onRetry: () {},
    );
    expect(find.textContaining('Koneksi terputus'), findsOneWidget);
  });

  testWidgets('tap Retry calls onRetry', (tester) async {
    var called = false;
    await _pumpView(
      tester,
      initial: const DataInitPaused(
        'offline',
        failedStep: 'krs_download',
        skippable: true,
      ),
      onRetry: () => called = true,
      onSkip: () {},
    );
    await tester.tap(find.text('Coba Lagi'));
    expect(called, isTrue);
  });

  testWidgets('tap Lewati calls onSkip', (tester) async {
    var called = false;
    await _pumpView(
      tester,
      initial: const DataInitPaused(
        'offline',
        failedStep: 'krs_download',
        skippable: true,
      ),
      onRetry: () {},
      onSkip: () => called = true,
    );
    await tester.tap(find.text('Lewati'));
    expect(called, isTrue);
  });

  testWidgets('tap Back to Login calls onCancel', (tester) async {
    var called = false;
    await _pumpView(
      tester,
      initial: const DataInitPaused(
        'offline',
        failedStep: 'profile_get',
        skippable: false,
      ),
      onRetry: () {},
      onCancel: () => called = true,
    );
    await tester.tap(find.text('Kembali ke Login'));
    expect(called, isTrue);
  });
}
