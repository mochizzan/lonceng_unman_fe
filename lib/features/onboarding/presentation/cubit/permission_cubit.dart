import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/services/fcm_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionState {
  const PermissionState({this.isGranted = false, this.isRequesting = false});
  final bool isGranted;
  final bool isRequesting;

  PermissionState copyWith({bool? isGranted, bool? isRequesting}) {
    return PermissionState(
      isGranted: isGranted ?? this.isGranted,
      isRequesting: isRequesting ?? this.isRequesting,
    );
  }
}

class PermissionCubit extends Cubit<PermissionState> {
  PermissionCubit() : super(const PermissionState());

  Future<void> checkPermission() async {
    debugPrint('[PERM] checkPermission() START');
    if (kIsWeb) {
      debugPrint('[PERM]   Web platform, auto-granting');
      emit(state.copyWith(isGranted: true));
      return;
    }
    debugPrint('[PERM]   Checking notification status...');
    final status = await Permission.notification.status;
    debugPrint('[PERM]   Status: ${status.isGranted}');
    emit(state.copyWith(isGranted: status.isGranted));
    debugPrint('[PERM] checkPermission() END');
  }

  Future<void> requestPermission() async {
    debugPrint('[PERM] requestPermission() START');
    if (state.isRequesting || state.isGranted) {
      debugPrint(
        '[PERM]   SKIP: already requesting=${state.isRequesting} granted=${state.isGranted}',
      );
      return;
    }
    emit(state.copyWith(isRequesting: true));
    debugPrint('[PERM]   Emitting isRequesting=true');
    try {
      debugPrint('[PERM]   Requesting notification permission...');
      final status = await Permission.notification.request();
      debugPrint(
        '[PERM]   Permission result: $status (granted=${status.isGranted})',
      );
      if (status.isGranted) {
        // Request FCM-level permission (iOS APNs) and re-fetch token.
        debugPrint('[PERM]   Requesting FCM permission...');
        await FcmService.instance.requestPermission();
        debugPrint('[PERM]   FCM permission OK');
        debugPrint('[PERM]   Refreshing token...');
        await FcmService.instance.refreshToken();
        debugPrint('[PERM]   Token refreshed OK');
      }
      emit(state.copyWith(isGranted: status.isGranted, isRequesting: false));
      debugPrint(
        '[PERM]   Emitting final state: isGranted=${status.isGranted}',
      );
    } catch (e) {
      debugPrint('[PERM]   CATCH: $e');
      emit(state.copyWith(isRequesting: false));
      debugPrint('[PERM]   Emitting isRequesting=false (recovery)');
    }
    debugPrint('[PERM] requestPermission() END');
  }
}
