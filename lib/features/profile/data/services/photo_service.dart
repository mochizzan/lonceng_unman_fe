// profile - Photo service
//
// Mengambil foto profil mahasiswa dari backend LMS.
// Endpoint: POST /api/v1/lms/student-profile/photo
// Response: raw binary JPEG (bukan JSON envelope).
// Karena itu, service ini menggunakan http.Client langsung
// (bukan ApiClient yang hanya handle JSON).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

/// Service untuk mengambil foto profil dari backend LMS.
///
/// Menggunakan [http.Client] langsung karena endpoint mengembalikan
/// raw binary JPEG, bukan JSON envelope seperti endpoint lain.
class PhotoService {
  PhotoService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppStrings.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(minutes: 2);

  /// Mengambil foto profil untuk [npm].
  ///
  /// Mengembalikan bytes JPEG bila foto ditemukan,
  /// atau null bila backend mengembalikan 204 (tidak ada foto).
  ///
  /// Melempar [NetworkException] bila koneksi gagal,
  /// atau [ServerException] bila server error.
  Future<Uint8List?> fetchPhoto({
    required String npm,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/lms/student-profile/photo');
      debugPrint('[PhotoService] Fetching photo for npm=$npm');

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'image/jpeg',
            },
            body: jsonEncode({'npm': npm, 'password': password}),
          )
          .timeout(_timeout);

      if (response.statusCode == 204) {
        debugPrint('[PhotoService] No photo found (204)');
        return null;
      }

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        debugPrint('[PhotoService] Photo fetched: ${bytes.length} bytes');
        return bytes;
      }

      // Map error status codes ke AppException
      if (response.statusCode == 401) {
        throw const AuthException('Sesi telah berakhir. Silakan login ulang.');
      }
      throw ServerException(
        'Gagal mengambil foto profil (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on AppException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server: ${e.message}');
    } on HandshakeException catch (e) {
      throw NetworkException('Koneksi tidak aman (TLS): ${e.message}');
    } on HttpException catch (e) {
      throw NetworkException('Koneksi terputus: ${e.message}');
    } on IOException catch (e) {
      throw NetworkException('Koneksi terputus: $e');
    } on http.ClientException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (e) {
      throw NetworkException('Koneksi timeout: ${e.message}');
    } on FormatException catch (e) {
      throw ServerException('Format respons tidak valid: ${e.message}');
    } catch (e) {
      throw ServerException('Terjadi kesalahan: $e');
    }
  }
}
