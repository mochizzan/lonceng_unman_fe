// Unit tests for [ConnectivityServiceImpl].
//
// `Connectivity` (from connectivity_plus) has a private constructor
// (see pub-cache/.../connectivity_plus-6.1.5/lib/connectivity_plus.dart),
// so the fake `implements` the public surface. Only `checkConnectivity`
// and `onConnectivityChanged` are needed by the production code.
//
// Hand-written fakes only — no mockito, no mocktail, no codegen.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity({
    List<ConnectivityResult> initial = const [ConnectivityResult.wifi],
  }) : _results = List<ConnectivityResult>.from(initial);

  List<ConnectivityResult> _results;
  final StreamController<List<ConnectivityResult>> _streamController =
      StreamController<List<ConnectivityResult>>.broadcast();

  void setResults(List<ConnectivityResult> results) {
    _results = results;
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _streamController.stream;

  void emit(List<ConnectivityResult> results) {
    _streamController.add(results);
  }

  // Silence `implements` requirement for any unused members.
  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ConnectivityServiceImpl', () {
    late _FakeConnectivity fake;
    late ConnectivityServiceImpl service;

    setUp(() {
      fake = _FakeConnectivity();
      service = ConnectivityServiceImpl(fake);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('isOnline defaults to true before first result arrives', () {
      // Constructor fires `checkConnectivity()` asynchronously; before it
      // resolves, the service reports `true` (no false-positive "offline"
      // flash on app launch).
      expect(service.isOnline, isTrue);
    });

    test('initial check with [wifi] keeps isOnline true', () async {
      // The constructor's fire-and-forget `checkConnectivity()` resolves on
      // the next microtask. Allow it to land.
      await Future<void>.delayed(Duration.zero);
      expect(service.isOnline, isTrue);
    });

    test(
      'stream emit [none] flips isOnline to false AND emits on stream',
      () async {
        final received = <bool>[];
        final sub = service.onStatusChange.listen(received.add);

        fake.emit([ConnectivityResult.none]);
        // Let the listen-handler process the stream event.
        await Future<void>.delayed(Duration.zero);

        expect(service.isOnline, isFalse);
        expect(received, contains(false));
        await sub.cancel();
      },
    );

    test('refresh() picks up new status', () async {
      // After [none] arrives via refresh(), isOnline must transition to false
      // and the controller must emit a `false` event.
      fake.setResults([ConnectivityResult.none]);

      final received = <bool>[];
      final sub = service.onStatusChange.listen(received.add);

      await service.refresh();
      // Broadcast stream delivers listeners' callbacks as a microtask —
      // yield once so the listener observes the transition.
      await Future<void>.delayed(Duration.zero);

      expect(service.isOnline, isFalse);
      expect(received, contains(false));
      await sub.cancel();
    });

    test('duplicate emits (online → online) are filtered', () async {
      // The implementation must only emit on real transitions. Two [wifi]
      // events back-to-back are no-ops and must NOT emit on the stream.
      final received = <bool>[];
      final sub = service.onStatusChange.listen(received.add);

      fake.emit([ConnectivityResult.wifi]);
      fake.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      await sub.cancel();
    });
  });
}
