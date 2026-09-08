// Unit tests for [DataInitBloc] — focus on the offline fail-fast path and
// the online happy/sad paths via the broadcast stream.
//
// Hand-written fakes only — no mockito, no mocktail, no codegen.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';

/// Hand-written fake [ConnectivityService] for bloc tests. Defaults to
/// online; flip [isOnline] to simulate a transition.
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

  /// Test helper — toggle + emit (mirror the production event surface).
  void setOnline(bool v) {
    _isOnline = v;
    _controller.add(v);
  }
}

/// Hand-written fake [GetDataInitialization] usecase. The returned stream
/// is broadcast so the bloc can subscribe once and the test can push events
/// on demand via [pushProgress].
class _FakeGetDataInit implements GetDataInitialization {
  _FakeGetDataInit();

  final _controller = StreamController<DataInitProgress>.broadcast();
  bool wasCalled = false;

  // [GetDataInitialization.repository] is a public field of type
  // [DataInitializationRepository]. The bloc under test never reads it
  // (it only calls `usecase(...)`), so the fake returns a sentinel
  // no-op repo. The cast through `dynamic` keeps the override
  // signature-compatible without dragging in a full implementation.
  @override
  DataInitializationRepository get repository => _NoOpRepo();

  @override
  Stream<DataInitProgress> call({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) {
    wasCalled = true;
    return _controller.stream;
  }

  void pushProgress(DataInitProgress p) {
    _controller.add(p);
  }
}

/// Sentinel repo referenced by [repository]. Never invoked.
class _NoOpRepo implements DataInitializationRepository {
  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) {
    return const Stream<DataInitProgress>.empty();
  }
}

void main() {
  group('DataInitBloc offline fail-fast', () {
    test(
      'offline → DataInitPaused(no_connection, skippable:false) + pipeline NOT called',
      () async {
        final fakeConn = _FakeConnectivityService(isOnline: false);
        final fakeGet = _FakeGetDataInit();
        final bloc = DataInitBloc(fakeGet, connectivity: fakeConn);

        final emitted = <DataInitBlocState>[];
        final sub = bloc.stream.listen(emitted.add);

        bloc.add(const DataInitStarted(npm: '123', password: 'pass'));
        // Two microtask hops — first lets the event handler run, second
        // lets the synchronous emit land on the stream.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(
          emitted,
          contains(
            const DataInitPaused(
              AppStrings.dataInitNoConnection,
              failedStep: 'no_connection',
              skippable: false,
            ),
          ),
        );
        expect(fakeGet.wasCalled, false);

        await sub.cancel();
        await bloc.close();
      },
    );

    test('online + completed stream → DataInitSuccess', () async {
      final fakeConn = _FakeConnectivityService(isOnline: true);
      final fakeGet = _FakeGetDataInit();
      final bloc = DataInitBloc(fakeGet, connectivity: fakeConn);

      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const DataInitStarted(npm: '123', password: 'pass'));
      // Let the bloc subscribe to the broadcast stream from `_FakeGetDataInit`.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      fakeGet.pushProgress(
        const DataInitProgress(DataInitStatus.scrapingProfile),
      );
      await Future<void>.delayed(Duration.zero);
      fakeGet.pushProgress(const DataInitProgress(DataInitStatus.completed));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        emitted,
        contains(const DataInitInProgress(DataInitStatus.scrapingProfile)),
      );
      expect(emitted, contains(const DataInitSuccess()));

      await sub.cancel();
      await bloc.close();
    });

    test('online + failed stream → DataInitFailure', () async {
      final fakeConn = _FakeConnectivityService(isOnline: true);
      final fakeGet = _FakeGetDataInit();
      final bloc = DataInitBloc(fakeGet, connectivity: fakeConn);

      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const DataInitStarted(npm: '123', password: 'pass'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      fakeGet.pushProgress(
        const DataInitProgress(DataInitStatus.scrapingProfile),
      );
      await Future<void>.delayed(Duration.zero);
      fakeGet.pushProgress(const DataInitProgress(DataInitStatus.failed));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        emitted,
        contains(const DataInitFailure('Gagal memuat data akademik')),
      );

      await sub.cancel();
      await bloc.close();
    });
  });
}
