// khs - KHS PDF Service
//
// Mengunduh file KHS PDF dari backend LMS dan menyimpannya ke direktori
// Downloads perangkat.
// Endpoint: POST /api/v1/lms/khs/file
// Response: raw binary PDF (Content-Type: application/pdf).
// Karena itu, service ini menggunakan http.Client langsung
// (bukan ApiClient yang hanya handle JSON).

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service untuk mengunduh file KHS PDF dari backend LMS.
///
/// Menggunakan [http.Client] langsung karena endpoint mengembalikan
/// raw binary PDF, bukan JSON envelope seperti endpoint lain.
///
/// File disimpan ke direktori Downloads perangkat dengan format nama:
/// `KHS_{tahunAjaran}_{semester}.pdf` (garis miring diganti underscore).
class KhsPdfService {
  KhsPdfService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppStrings.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 60);

  /// Mengunduh KHS PDF dan menyimpan ke direktori Downloads.
  ///
  /// Mengembalikan path file pada saat sukses.
  ///
  /// Melempar [NetworkException] bila koneksi gagal,
  /// atau [ServerException] bila server error.
  Future<String> download({
    required String npm,
    required String password,
    required String tahunAjaran,
    required String semester,
  }) async {
    // 1. Check storage permission (pre-Android 10)
    await _checkStoragePermission();

    // 2. Get Downloads directory via path_provider
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw const ServerException('Tidak dapat mengakses direktori Downloads');
    }

    // 3. Call POST /api/v1/lms/khs/file with credentials
    final sanitizedTahunAjaran = tahunAjaran.replaceAll('/', '_');
    final fileName = 'KHS_${sanitizedTahunAjaran}_$semester.pdf';
    final filePath = '${directory.path}/$fileName';

    debugPrint('[KhsPdfService] Downloading KHS PDF: $fileName');
    debugPrint(
      '[KhsPdfService] Tahun Ajaran: $tahunAjaran, Semester: $semester',
    );

    try {
      final uri = Uri.parse('$_baseUrl/api/v1/lms/khs/file');
      final body = lmsCredentialBody(
        npm: npm,
        password: password,
        tahunAjaran: tahunAjaran,
        semester: semester,
      );

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/pdf',
            },
            body: body,
          )
          .timeout(_timeout);

      // 4. Check response status (200 = PDF bytes)
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        debugPrint('[KhsPdfService] PDF downloaded: ${bytes.length} bytes');

        // 5. Write bytes to file
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        debugPrint('[KhsPdfService] PDF saved to: $filePath');

        // 6. Return file path
        return filePath;
      }

      // Map error status codes ke AppException
      if (response.statusCode == 401) {
        throw const AuthException('Sesi telah berakhir. Silakan login ulang.');
      }
      if (response.statusCode == 404) {
        throw const ServerException(
          'File KHS tidak ditemukan',
          statusCode: 404,
        );
      }
      throw ServerException(
        'Gagal mengunduh KHS PDF (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (e) {
      throw NetworkException('Koneksi timeout: ${e.message}');
    } on AppException {
      rethrow;
    } on FormatException catch (e) {
      throw ServerException('Format respons tidak valid: ${e.message}');
    } catch (e) {
      throw ServerException('Terjadi kesalahan: $e');
    }
  }

  /// Memeriksa izin penyimpanan untuk Android < 10.
  ///
  /// Pada Android 10+ (API 29+), scoped storage berarti tidak diperlukan
  /// izin tambahan untuk menulis ke direktori Downloads.
  ///
  /// [Permission.storage] hanya di-resolve untuk Android < 10. Pada
  /// Android 10+, permission_handler mengembalikan "not found in manifest"
  /// warning karena WRITE_EXTERNAL_STORAGE sudah tidak berlaku — ini
  /// bukan error dan diabaikan.
  Future<void> _checkStoragePermission() async {
    if (!Platform.isAndroid) return;

    // Android 10+ (API 29+) menggunakan scoped storage — tidak perlu
    // izin tambahan untuk menulis ke direktori Downloads.
    try {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          throw const ServerException(
            'Izin penyimpanan diperlukan untuk mengunduh file KHS',
          );
        }
      }
      debugPrint('[KhsPdfService] Storage permission granted');
    } on Exception catch (e) {
      // Android 10+ throws when resolving WRITE_EXTERNAL_STORAGE since
      // it's scoped-storage — this is expected and safe to ignore.
      debugPrint(
        '[KhsPdfService] Skipping storage permission on Android 10+: $e',
      );
    }
  }
}
