// Verification for fix: Buka/Bagikan now show visible feedback via onFeedback
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/khs/data/services/khs_download_notification_controller.dart';

class CapturingService extends NotificationService {
  CapturingService() : super();
  @override
  Future<bool> checkPermissionStatus() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required dynamic channel,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
    List<AndroidNotificationAction>? actions,
  }) async {}
  @override
  Future<void> initialize() async {}
}

void main() {
  late Directory tmp;
  late String existingPath;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('khs_fix_verify_');
    final f = File('${tmp.path}/KHS_2025_2026_GANJIL.pdf');
    await f.writeAsBytes([0x25, 0x50, 0x44, 0x46]);
    existingPath = f.path;
  });

  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } catch (_) {}
  });

  test('fix: open no-app now triggers visible feedback (not silent)', () async {
    String? feedback;
    final ctrl = KhsDownloadNotificationController(
      notificationService: CapturingService(),
      openFile: (p) async => false, // simulasi no viewer
      onFeedback: (m) => feedback = m,
    );

    ctrl.handleResponse(
      NotificationResponse(
        id: KhsDownloadNotificationController.notificationId,
        actionId: 'open',
        payload: existingPath,
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(feedback, AppStrings.khsDownloadNoViewer);
  });

  test('fix: open missing file triggers feedback', () async {
    String? feedback;
    final ctrl = KhsDownloadNotificationController(
      notificationService: CapturingService(),
      openFile: (p) async => true,
      onFeedback: (m) => feedback = m,
    );

    ctrl.handleResponse(
      NotificationResponse(
        id: KhsDownloadNotificationController.notificationId,
        actionId: 'open',
        payload: '/tmp/does_not_exist_123.pdf',
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(feedback, AppStrings.khsDownloadFileNotFound);
  });

  test('fix: share failure triggers feedback', () async {
    String? feedback;
    final ctrl = KhsDownloadNotificationController(
      notificationService: CapturingService(),
      shareFile: (p) async => throw Exception('share failed'),
      onFeedback: (m) => feedback = m,
    );
    ctrl.handleResponse(
      NotificationResponse(
        id: KhsDownloadNotificationController.notificationId,
        actionId: 'share',
        payload: existingPath,
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(feedback, AppStrings.khsDownloadShareFailed);
  });

  test('fix: body tap with empty payload triggers feedback', () async {
    String? feedback;
    final ctrl = KhsDownloadNotificationController(
      notificationService: CapturingService(),
      onFeedback: (m) => feedback = m,
    );
    ctrl.handleResponse(
      NotificationResponse(
        id: KhsDownloadNotificationController.notificationId,
        actionId: null,
        payload: '',
        notificationResponseType: NotificationResponseType.selectedNotification,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(feedback, AppStrings.khsDownloadFileNotFound);
  });

  test('fix: open success does NOT trigger feedback', () async {
    String? feedback;
    final ctrl = KhsDownloadNotificationController(
      notificationService: CapturingService(),
      openFile: (p) async => true,
      onFeedback: (m) => feedback = m,
    );
    ctrl.handleResponse(
      NotificationResponse(
        id: KhsDownloadNotificationController.notificationId,
        actionId: 'open',
        payload: existingPath,
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(feedback, isNull);
  });
}
