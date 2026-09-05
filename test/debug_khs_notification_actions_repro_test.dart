// Repro harness for KHS notification actions Buka/Bagikan (readonly investigation)
// Membuktikan routing controller BUKAN penyebab; yang hilang adalah background callback registration.
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
    tmp = await Directory.systemTemp.createTemp('khs_actions_repro_');
    final f = File('${tmp.path}/KHS_2025_2026_GANJIL.pdf');
    await f.writeAsBytes([0x25, 0x50, 0x44, 0x46]);
    existingPath = f.path;
  });
  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } catch (_) {}
  });

  group('REPRO: controller routing (foreground) — should already pass', () {
    test('foreground open action routes to openFile', () async {
      String? opened;
      final ctrl = KhsDownloadNotificationController(
        notificationService: CapturingService(),
        openFile: (p) async {
          opened = p;
          return true;
        },
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
      expect(opened, existingPath);
    });

    test('foreground share action routes to shareFile', () async {
      String? shared;
      final ctrl = KhsDownloadNotificationController(
        notificationService: CapturingService(),
        shareFile: (p) async {
          shared = p;
        },
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
      expect(shared, existingPath);
    });

    test('foreground open no-viewer triggers feedback', () async {
      String? fb;
      final ctrl = KhsDownloadNotificationController(
        notificationService: CapturingService(),
        openFile: (p) async => false,
        onFeedback: (m) => fb = m,
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
      expect(fb, AppStrings.khsDownloadNoViewer);
    });
  });

  group('VERIFY: background callback — fixed', () {
    test('NotificationService now registers background handler', () {
      final src = File(
        'lib/core/services/notification_service.dart',
      ).readAsStringSync();
      final hasBg = src.contains('onDidReceiveBackgroundNotificationResponse');
      expect(
        hasBg,
        isTrue,
        reason: 'Fix: background handler must be registered.',
      );
    });

    test('actions use showsUserInterface to bring foreground', () {
      final src = File(
        'lib/features/khs/data/services/khs_download_notification_controller.dart',
      ).readAsStringSync();
      final hasShowsUi = src.contains('showsUserInterface');
      expect(
        hasShowsUi,
        isTrue,
        reason: 'Fix: actions must use showsUserInterface:true',
      );
    });
  });
}
