// test/core/errors/app_errors_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

void main() {
  group('NetworkException', () {
    test('is an AppException', () {
      const exception = NetworkException('test error');
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('has correct default code', () {
      const exception = NetworkException('test error');
      expect(exception.code, 'NETWORK_ERROR');
    });

    test('has correct message', () {
      const exception = NetworkException('No internet');
      expect(exception.message, 'No internet');
    });
  });

  group('ServerException', () {
    test('is an AppException', () {
      const exception = ServerException('test error');
      expect(exception, isA<AppException>());
    });

    test('has correct default code', () {
      const exception = ServerException('test error');
      expect(exception.code, 'SERVER_ERROR');
    });

    test('stores status code', () {
      const exception = ServerException('test', statusCode: 404);
      expect(exception.statusCode, 404);
    });
  });

  group('AuthException', () {
    test('is an AppException', () {
      const exception = AuthException('test error');
      expect(exception, isA<AppException>());
    });

    test('has correct default code', () {
      const exception = AuthException('test error');
      expect(exception.code, 'AUTH_ERROR');
    });
  });

  group('ValidationException', () {
    test('is an AppException', () {
      const exception = ValidationException('test error');
      expect(exception, isA<AppException>());
    });

    test('has correct default code', () {
      const exception = ValidationException('test error');
      expect(exception.code, 'VALIDATION_ERROR');
    });
  });
}
