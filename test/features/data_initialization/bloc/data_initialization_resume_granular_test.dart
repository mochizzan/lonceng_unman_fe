// Phase 4 systematic-debugging: failing test for M2 granular resume.
// KRS/KHS retry must NOT re-scrape profile; profile retry must.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';

class _FakeConn implements ConnectivityService {
  bool _online;
  _FakeConn(this._online);
  final _c = StreamController<bool>.broadcast();
  @override
  bool get isOnline => _online;
  @override
  Stream<bool> get onStatusChange => _c.stream;
  @override
  Future<void> refresh() async {}
  void setOnline(bool v) => _online = v;
}

/// Repository that fails once at [failStep] then succeeds via resumeFrom
/// without re-emitting scrapingProfile.
class _FailOnceRepo implements DataInitializationRepository {
  final String failStep;
  int initializeCalls = 0;
  int resumeCalls = 0;
  final List<String> resumeFailedSteps = [];
  final List<DataInitStatus> emittedStatuses = [];

  _FailOnceRepo(this.failStep);

  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) async* {
    initializeCalls++;
    emittedStatuses.add(DataInitStatus.scrapingProfile);
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    throw DataInitStepException(
      failStep,
      'Network offline',
      const NetworkException('offline'),
    );
  }

  @override
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  }) async* {
    resumeCalls++;
    resumeFailedSteps.add(failedStep);
    // Granular: emit only the failed step onward, no scrapingProfile
    if (failedStep.startsWith('khs')) {
      emittedStatuses.add(DataInitStatus.downloadingKhs);
      yield const DataInitProgress(
        DataInitStatus.downloadingKhs,
        detail: '2024/2025 Ganjil',
      );
      yield const DataInitProgress(DataInitStatus.completed);
    } else if (failedStep.startsWith('krs')) {
      emittedStatuses.add(DataInitStatus.downloadingKrs);
      yield const DataInitProgress(DataInitStatus.downloadingKrs);
      yield const DataInitProgress(DataInitStatus.completed);
    } else {
      emittedStatuses.add(DataInitStatus.scrapingProfile);
      yield const DataInitProgress(DataInitStatus.scrapingProfile);
      yield const DataInitProgress(DataInitStatus.completed);
    }
  }
}

void main() {
  test(
    'KHS retry online uses resumeFrom not full restart — no second scrapingProfile',
    () async {
      final repo = _FailOnceRepo('khs_download_Ganjil');
      final conn = _FakeConn(true);
      final bloc = DataInitBloc(
        GetDataInitialization(repo),
        connectivity: conn,
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const DataInitStarted(npm: 'npm', password: 'pwd'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        emitted.any(
          (s) => s is DataInitPaused && s.failedStep == 'khs_download_Ganjil',
        ),
        isTrue,
      );
      expect(repo.initializeCalls, 1);
      expect(repo.resumeCalls, 0);

      // Online retry — should go through resumeFrom
      bloc.add(const DataInitRetry());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(repo.resumeCalls, 1, reason: 'KHS retry must use resumeFrom');
      expect(repo.resumeFailedSteps.first, 'khs_download_Ganjil');
      expect(
        repo.initializeCalls,
        1,
        reason: 'must NOT re-initialize (no second scrapingProfile)',
      );
      // Only one scrapingProfile total
      expect(
        repo.emittedStatuses
            .where((s) => s == DataInitStatus.scrapingProfile)
            .length,
        1,
      );
      expect(emitted.last, isA<DataInitSuccess>());

      await sub.cancel();
      await bloc.close();
    },
  );

  test('KRS retry online uses resumeFrom', () async {
    final repo = _FailOnceRepo('krs_download');
    final conn = _FakeConn(true);
    final bloc = DataInitBloc(GetDataInitialization(repo), connectivity: conn);
    final emitted = <DataInitBlocState>[];
    final sub = bloc.stream.listen(emitted.add);

    bloc.add(const DataInitStarted(npm: 'npm', password: 'pwd'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    bloc.add(const DataInitRetry());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(repo.resumeCalls, 1);
    expect(repo.initializeCalls, 1);
    await sub.cancel();
    await bloc.close();
  });

  test('Profile retry still does full restart via initialize', () async {
    final repo = _FailOnceRepo('profile_get');
    final conn = _FakeConn(true);
    final bloc = DataInitBloc(GetDataInitialization(repo), connectivity: conn);
    final emitted = <DataInitBlocState>[];
    final sub = bloc.stream.listen(emitted.add);

    bloc.add(const DataInitStarted(npm: 'npm', password: 'pwd'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      emitted.any((s) => s is DataInitPaused && s.failedStep == 'profile_get'),
      isTrue,
    );

    bloc.add(const DataInitRetry());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      repo.resumeCalls,
      0,
      reason: 'profile retry must NOT use resumeFrom',
    );
    expect(repo.initializeCalls, 2, reason: 'profile retry is full restart');
    await sub.cancel();
    await bloc.close();
  });

  test(
    'Retry while offline preserves paused and does not call resumeFrom',
    () async {
      final repo = _FailOnceRepo('khs_download_Ganjil');
      final conn = _FakeConn(true);
      final bloc = DataInitBloc(
        GetDataInitialization(repo),
        connectivity: conn,
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const DataInitStarted(npm: 'npm', password: 'pwd'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      conn.setOnline(false);
      bloc.add(const DataInitRetry());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(repo.resumeCalls, 0);
      expect(repo.initializeCalls, 1);
      expect(bloc.state, isA<DataInitPaused>());
      expect(
        (bloc.state as DataInitPaused).skippable,
        isTrue,
        reason: 'Lewati must stay',
      );
      await sub.cancel();
      await bloc.close();
    },
  );
}
