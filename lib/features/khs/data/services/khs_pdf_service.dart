// khs - KHS PDF Service
//
// Mengunduh file KHS PDF dari backend LMS dan menyimpannya ke direktori
// Downloads perangkat.
// Endpoint: POST /api/v1/lms/khs/file
// Response: raw binary PDF (Content-Type: application/pdf).
// Karena itu, service ini menggunakan http.Client langsung
// (bukan ApiClient yang hanya handle JSON).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/credential_body.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service untuk mengunduh file KHS PDF dari backend LMS.
///
/// Menggunakan [http.Client] langsung karena endpoint mengembalikan
/// raw binary PDF, bukan JSON envelope seperti endpoint lain.
///
/// File disimpan ke direktori publik perangkat:
/// `/storage/emulated/0/Document/LoncengUnMan/KHS/` dengan format nama:
/// `KHS_{tahunAjaran}_{semester}.pdf`.
class KhsPdfService {
  KhsPdfService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppStrings.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 60);

  /// Mengunduh KHS PDF dan menyimpan ke direktori publik.
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
    await _checkStoragePermission();

    final sanitizedTahunAjaran = tahunAjaran.replaceAll('/', '_');
    final fileName = 'KHS_${sanitizedTahunAjaran}_$semester.pdf';
    final filePath = await _buildPublicPath(fileName);

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
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        debugPrint('[KhsPdfService] PDF downloaded: ${bytes.length} bytes');

        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        debugPrint('[KhsPdfService] PDF saved to: $filePath');
        return filePath;
      }

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

  /// Membangun path publik untuk menyimpan file KHS.
  ///
  /// Target: `/storage/emulated/0/Documents/LoncengUnMan/KHS/{fileName}`
  Future<String> _buildPublicPath(String fileName) async {
    const baseDir = '/storage/emulated/0/Documents/LoncengUnMan/KHS';
    final targetDir = Directory(baseDir);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }
    return '$baseDir/$fileName';
  }

  /// Memeriksa dan meminta izin penyimpanan sesuai versi Android.
  ///
  /// - Android 9 dan bawah (API 28-): request WRITE_EXTERNAL_STORAGE (popup sistem)
  /// - Android 10 (API 29): requestLegacyExternalStorage di manifest, tidak perlu runtime permission
  /// - Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE (buka Settings, bukan popup)
  Future<void> _checkStoragePermission() async {
    if (!Platform.isAndroid) return;

    // Cek apakah MANAGE_EXTERNAL_STORAGE tersedia (Android 11+)
    final manageStatus = await Permission.manageExternalStorage.status;
    final isManageSupported = manageStatus != PermissionStatus.restricted;

    if (isManageSupported) {
      // Android 11+: gunakan MANAGE_EXTERNAL_STORAGE
      final hasAccess = await Permission.manageExternalStorage.isGranted;
      if (!hasAccess) {
        // Request akan membuka Settings, bukan popup
        // User harus grant manual di Settings
        final result = await Permission.manageExternalStorage.request();
        debugPrint('[KhsPdfService] MANAGE_EXTERNAL_STORAGE result: $result');
      }
    } else {
      // Android 10 dan bawah: gunakan storage permission
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          throw const ServerException(
            'Izin penyimpanan diperlukan untuk mengunduh file KHS',
          );
        }
      }
    }
  }
}
