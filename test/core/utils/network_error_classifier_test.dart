import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/network_error_classifier.dart';

void main() {
  group('isNetworkError', () {
    test('NetworkException -> true', () {
      expect(isNetworkError(const NetworkException('x')), isTrue);
    });

    test('TimeoutException -> true', () {
      expect(
        isNetworkError(TimeoutException('x', const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('DataInitStepException wrapping NetworkException -> true', () {
      const e = DataInitStepException(
        'krs_download',
        'msg',
        NetworkException('x'),
      );
      expect(isNetworkError(e), isTrue);
    });

    test('ServerException -> false', () {
      expect(isNetworkError(const ServerException('x')), isFalse);
    });

    test('AuthException -> false', () {
      expect(isNetworkError(const AuthException('x')), isFalse);
    });

    test('failedStep no_connection -> true', () {
      const e = DataInitStepException('no_connection', 'msg');
      expect(isNetworkError(e, failedStep: 'no_connection'), isTrue);
    });
  });

  group('isProfileStep', () {
    test('profile_* -> true', () {
      expect(isProfileStep('profile_scrape_1'), isTrue);
      expect(isProfileStep('profile_get'), isTrue);
    });

    test('krs/khs -> false', () {
      expect(isProfileStep('krs_download'), isFalse);
      expect(isProfileStep('khs_download_Ganjil'), isFalse);
    });
  });
}
