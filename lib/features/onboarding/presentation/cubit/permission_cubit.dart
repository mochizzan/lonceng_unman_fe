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
    if (kIsWeb) {
      emit(state.copyWith(isGranted: true));
      return;
    }
    final status = await Permission.notification.status;
    emit(state.copyWith(isGranted: status.isGranted));
  }

  Future<void> requestPermission() async {
    if (state.isRequesting || state.isGranted) return;
    emit(state.copyWith(isRequesting: true));
    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        // Request FCM-level permission (iOS APNs) and re-fetch token.
        await FcmService.instance.requestPermission();
        await FcmService.instance.refreshToken();
      }
      emit(state.copyWith(isGranted: status.isGranted, isRequesting: false));
    } catch (_) {
      emit(state.copyWith(isRequesting: false));
    }
  }
}
