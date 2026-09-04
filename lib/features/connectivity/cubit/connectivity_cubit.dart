// Listens to [ConnectivityService] and re-emits each transition as a
// new [ConnectivityState]. Single instance app-wide, provided at the
// root via MultiBlocProvider.
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(ConnectivityService service)
    : _service = service,
      super(ConnectivityState(isOnline: service.isOnline)) {
    _subscription = _service.onStatusChange.listen((online) {
      if (isClosed) return;
      emit(ConnectivityState(isOnline: online));
    });
  }

  final ConnectivityService _service;
  late final StreamSubscription<bool> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
