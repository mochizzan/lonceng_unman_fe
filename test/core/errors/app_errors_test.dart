// test/core/errors/app_errors_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

void main() {
  group('NotificationException', () {
    test('is an AppException', () {
      const exception = NotificationException('test error');
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('has correct default code', () {
      const exception = NotificationException('test error');
      expect(exception.code, 'NOTIFICATION_ERROR');
    });

    test('has correct message', () {
      const exception = NotificationException('Schedule failed');
      expect(exception.message, 'Schedule failed');
    });

    test('can override code', () {
      const exception = NotificationException(
        'Channel error',
        code: 'CHANNEL_ERROR',
      );
      expect(exception.code, 'CHANNEL_ERROR');
    });

    test('toString includes message and code', () {
      const exception = NotificationException('test');
      expect(exception.toString(), contains('test'));
      expect(exception.toString(), contains('NOTIFICATION_ERROR'));
    });
  });
}
