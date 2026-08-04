// test/core/services/notification_service_test.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('can be instantiated with default plugin', () {
      final service = NotificationService();
      expect(service, isA<NotificationService>());
    });

    test('can be instantiated with custom plugin', () {
      final plugin = FlutterLocalNotificationsPlugin();
      final service = NotificationService(plugin: plugin);
      expect(service, isA<NotificationService>());
    });
  });
}
