// 409 AlumniException mapping — AC3
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';

void main() {
  group('ApiClient 409 Alumni', () {
    test('409 maps to AlumniException with isAlumniError true', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': 'error',
            'message': 'Mahasiswa status ALUMNI — KRS tidak tersedia',
            'trace_id': 't',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(baseUrl: 'http://example.test', client: client);

      try {
        await api.post('/api/v1/lms/krs/data', body: {'npm': '12345678'});
        fail('should throw');
      } catch (e) {
        expect(e, isA<AlumniException>());
        expect((e as AlumniException).statusCode, 409);
        expect(isAlumniError(e), isTrue);
      }
    });

    test('404 maps to ServerException with isAlumniError false', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({'status': 'error', 'message': 'Not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(baseUrl: 'http://example.test', client: client);

      try {
        await api.post('/api/v1/lms/krs/data', body: {'npm': '12345678'});
        fail('should throw');
      } catch (e) {
        expect(e, isA<ServerException>());
        expect(isAlumniError(e), isFalse);
      }
    });

    test('500 maps to ServerException', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({'status': 'error', 'message': 'Internal'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(baseUrl: 'http://example.test', client: client);
      try {
        await api.post('/x', body: {'npm': '12345678'});
        fail('should throw');
      } catch (e) {
        expect(e, isA<ServerException>());
        expect(isAlumniError(e), isFalse);
      }
    });
  });
}
