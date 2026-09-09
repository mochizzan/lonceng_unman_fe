// Paused/Retry/Skip behavior for DataInitBloc.
// Hand-written fakes only.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';

class FakeConnectivity implements ConnectivityService {
  FakeConnectivity({bool isOnline = true}) : _isOnline = isOnline;
  bool _isOnline;
  final _c = StreamController<bool>.broadcast();
  @override
  bool get isOnline => _isOnline;
  @override
  Stream<bool> get onStatusChange => _c.stream;
  @override
  Future<void> refresh() async {}
}

class NoOpRepo implements DataInitializationRepository {
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

/// Repository that throws DataInitStepException per step label.
class ThrowingRepo implements DataInitializationRepository {
  final String step;
  final Object error;
  ThrowingRepo(this.step, this.error);

  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) async* {
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    throw DataInitStepException(step, error.toString(), error);
  }

  @override
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  }) async* {
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    throw DataInitStepException(step, error.toString(), error);
  }
}

class SuccessRepo implements DataInitializationRepository {
  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  }) async* {
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    yield const DataInitProgress(DataInitStatus.completed);
  }

  @override
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  }) async* {
    yield const DataInitProgress(DataInitStatus.scrapingProfile);
    yield const DataInitProgress(DataInitStatus.completed);
  }
}

Future<DataInitBloc> _makeBloc(DataInitializationRepository repo) async {
  final bloc = DataInitBloc(
    GetDataInitialization(repo),
    connectivity: FakeConnectivity(isOnline: true),
  );
  return bloc;
}

void main() {
  group('DataInitBloc paused', () {
    test('offline fail-fast → Paused no_connection skippable false', () async {
      final bloc = DataInitBloc(
        GetDataInitialization(NoOpRepo()),
        connectivity: FakeConnectivity(isOnline: false),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
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
      await sub.cancel();
      await bloc.close();
    });

    test('krs_download network → Paused skippable true', () async {
      final bloc = await _makeBloc(
        ThrowingRepo('krs_download', const NetworkException('offline')),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        emitted.any(
          (s) =>
              s is DataInitPaused &&
              s.failedStep == 'krs_download' &&
              s.skippable == true,
        ),
        isTrue,
      );
      await sub.cancel();
      await bloc.close();
    });

    test('khs_download network → Paused skippable true', () async {
      final bloc = await _makeBloc(
        ThrowingRepo('khs_download_Ganjil', const NetworkException('offline')),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        emitted.any(
          (s) =>
              s is DataInitPaused &&
              s.failedStep == 'khs_download_Ganjil' &&
              s.skippable == true,
        ),
        isTrue,
      );
      await sub.cancel();
      await bloc.close();
    });

    test('profile_get network → Paused skippable false', () async {
      final bloc = await _makeBloc(
        ThrowingRepo('profile_get', const NetworkException('offline')),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        emitted.any(
          (s) =>
              s is DataInitPaused &&
              s.failedStep == 'profile_get' &&
              s.skippable == false,
        ),
        isTrue,
      );
      await sub.cancel();
      await bloc.close();
    });

    test('profile_get ServerException → Failure not Paused', () async {
      final bloc = await _makeBloc(
        ThrowingRepo('profile_get', const ServerException('500')),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted.any((s) => s is DataInitFailure), isTrue);
      expect(emitted.any((s) => s is DataInitPaused), isFalse);
      await sub.cancel();
      await bloc.close();
    });

    test('TimeoutException → Paused timeout', () async {
      final bloc = await _makeBloc(
        ThrowingRepo(
          'timeout',
          TimeoutException('t', const Duration(seconds: 1)),
        ),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        emitted.any((s) => s is DataInitPaused && s.failedStep == 'timeout'),
        isTrue,
      );
      await sub.cancel();
      await bloc.close();
    });

    test('Retry after paused re-dispatches Started', () async {
      final throwing = ThrowingRepo(
        'krs_download',
        const NetworkException('offline'),
      );
      final bloc = DataInitBloc(
        GetDataInitialization(throwing),
        connectivity: FakeConnectivity(isOnline: true),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted.any((s) => s is DataInitPaused), isTrue);
      // Retry should re-emit scrapingProfile (full restart M1)
      bloc.add(const DataInitRetry());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Second scrapingProfile after retry
      final scrapingCount = emitted
          .whereType<DataInitInProgress>()
          .where((s) => s.status == DataInitStatus.scrapingProfile)
          .length;
      expect(scrapingCount, greaterThanOrEqualTo(2));
      await sub.cancel();
      await bloc.close();
    });

    test('Skip after paused skippable → partial Success', () async {
      final bloc = await _makeBloc(
        ThrowingRepo('krs_download', const NetworkException('offline')),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const DataInitSkip());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(
        emitted.any(
          (s) =>
              s is DataInitSuccess &&
              s.isPartial == true &&
              s.skippedSteps.contains('krs_download'),
        ),
        isTrue,
      );
      await sub.cancel();
      await bloc.close();
    });

    test('Skip after profile paused → no-op stays Paused', () async {
      final bloc = await _makeBloc(
        ThrowingRepo('profile_get', const NetworkException('offline')),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final before = emitted.length;
      bloc.add(const DataInitSkip());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, before);
      expect(emitted.last is DataInitPaused, isTrue);
      await sub.cancel();
      await bloc.close();
    });

    test(
      'krs_download http.ClientException → Paused skippable true (not Success)',
      () async {
        final bloc = await _makeBloc(
          ThrowingRepo(
            'krs_download',
            http.ClientException('Failed host lookup'),
          ),
        );
        final emitted = <DataInitBlocState>[];
        final sub = bloc.stream.listen(emitted.add);
        bloc.add(const DataInitStarted(npm: '1', password: 'p'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          emitted.any(
            (s) =>
                s is DataInitPaused &&
                s.failedStep == 'krs_download' &&
                s.skippable,
          ),
          isTrue,
        );
        expect(emitted.any((s) => s is DataInitSuccess), isFalse);
        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'khs_download_Ganjil HandshakeException → Paused skippable true',
      () async {
        final bloc = await _makeBloc(
          ThrowingRepo('khs_download_Ganjil', const HandshakeException('TLS')),
        );
        final emitted = <DataInitBlocState>[];
        final sub = bloc.stream.listen(emitted.add);
        bloc.add(const DataInitStarted(npm: '1', password: 'p'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emitted.any((s) => s is DataInitPaused && s.skippable), isTrue);
        await sub.cancel();
        await bloc.close();
      },
    );

    test('profile_get ClientException → Paused skippable false', () async {
      final bloc = await _makeBloc(
        ThrowingRepo('profile_get', http.ClientException('offline')),
      );
      final emitted = <DataInitBlocState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const DataInitStarted(npm: '1', password: 'p'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        emitted.any(
          (s) =>
              s is DataInitPaused &&
              s.failedStep == 'profile_get' &&
              !s.skippable,
        ),
        isTrue,
      );
      await sub.cancel();
      await bloc.close();
    });
  });
}
