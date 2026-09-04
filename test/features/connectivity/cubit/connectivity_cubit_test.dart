// Unit tests for [ConnectivityCubit]. The cubit mirrors transitions on
// the [ConnectivityService.onStatusChange] stream into [ConnectivityState]
// events. Initial state is read synchronously from `service.isOnline`.
//
// Hand-written fakes only — no mockito, no mocktail, no codegen.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_state.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({bool initial = true}) : _isOnline = initial;

  bool _isOnline;
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  @override
  Future<void> refresh() async {}

  /// Test driver: simulate a transition on the service's stream.
  void emit(bool v) {
    _isOnline = v;
    _controller.add(v);
  }
}

void main() {
  group('ConnectivityCubit', () {
    test('initial state matches service.isOnline=true', () {
      final fake = _FakeConnectivityService(initial: true);
      final cubit = ConnectivityCubit(fake);
      expect(cubit.state, const ConnectivityState(isOnline: true));
      cubit.close();
    });

    test('initial state matches service.isOnline=false', () {
      final fake = _FakeConnectivityService(initial: false);
      final cubit = ConnectivityCubit(fake);
      expect(cubit.state, const ConnectivityState(isOnline: false));
      cubit.close();
    });

    test('service emit false → state becomes offline', () async {
      final fake = _FakeConnectivityService(initial: true);
      final cubit = ConnectivityCubit(fake);

      fake.emit(false);
      // The cubit subscribes synchronously inside the constructor; allow
      // the stream listener to deliver the event on the next microtask.
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const ConnectivityState(isOnline: false));
      await cubit.close();
    });

    test('service emit true → state becomes online', () async {
      final fake = _FakeConnectivityService(initial: false);
      final cubit = ConnectivityCubit(fake);

      fake.emit(true);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const ConnectivityState(isOnline: true));
      await cubit.close();
    });

    test('close() cancels subscription — further emits do not throw', () async {
      final fake = _FakeConnectivityService(initial: true);
      final cubit = ConnectivityCubit(fake);

      // Sanity: state is online before close.
      expect(cubit.state.isOnline, isTrue);

      await cubit.close();

      // Emit after close — must not throw. The cubit's subscription was
      // cancelled, so the broadcast stream silently drops the event.
      expect(() => fake.emit(false), returnsNormally);
    });
  });
}
