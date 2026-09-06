import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/services/fcm_service.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';

class CapturingNotificationService extends NotificationService {
  int? lastId;
  String? lastTitle;
  String? lastBody;
  NotificationChannel? lastChannel;
  int callCount = 0;
  bool shouldThrow = false;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationChannel channel,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
    List<AndroidNotificationAction>? actions,
  }) async {
    if (shouldThrow) throw StateError('show boom');
    lastId = id;
    lastTitle = title;
    lastBody = body;
    lastChannel = channel;
    callCount++;
  }
}

void main() {
  group('FcmService foreground show', () {
    tearDown(() {
      FcmService.instance.setNotificationServiceForTest(null);
    });

    test('notification payload shows via classReminders channel', () async {
      final cap = CapturingNotificationService();
      FcmService.instance.setNotificationServiceForTest(cap);
      final msg = RemoteMessage(
        messageId: 'mid-1',
        notification: const RemoteNotification(title: 'T', body: 'B'),
        data: const {'foo': 'bar'},
      );
      FcmService.instance.handleForegroundMessageForTest(msg);
      // _handleForegroundMessage is sync; allow async show microtask if any
      await Future<void>.delayed(Duration.zero);
      expect(cap.callCount, 1);
      expect(cap.lastChannel, NotificationChannel.classReminders);
      expect(cap.lastId, isNotNull);
      expect(cap.lastId! >= 0, isTrue);
      expect(cap.lastId, 'mid-1'.hashCode & 0x7FFFFFFF);
      expect(cap.lastTitle, 'T');
      expect(cap.lastBody, 'B');
    });

    test('data-only message does not show', () async {
      final cap = CapturingNotificationService();
      FcmService.instance.setNotificationServiceForTest(cap);
      final msg = RemoteMessage(data: const {'foo': 'bar'});
      FcmService.instance.handleForegroundMessageForTest(msg);
      await Future<void>.delayed(Duration.zero);
      expect(cap.callCount, 0);
    });

    test('show throw is swallowed', () async {
      final cap = CapturingNotificationService()..shouldThrow = true;
      FcmService.instance.setNotificationServiceForTest(cap);
      final msg = RemoteMessage(
        messageId: 'mid-2',
        notification: const RemoteNotification(title: 'X', body: 'Y'),
      );
      // should not throw
      expect(
        () => FcmService.instance.handleForegroundMessageForTest(msg),
        returnsNormally,
      );
      await Future<void>.delayed(Duration.zero);
      // swallowed, so no crash; callCount stays 0 because throw before increment
      // but main assertion is no exception
    });
  });
}
