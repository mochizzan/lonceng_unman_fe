import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:lonceng_unman_fe/core/constants/app_durations.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

/// Base API client for HTTP communication.
///
/// Provides configurable base URL, timeout, and consistent error handling
/// through the shared API response envelope:
///   success → {"status": "success", "data": {}, "message": "..."}
///   error   → {"status": "error", "message": "...", "trace_id": "...", "errors": {}}
class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.timeout = AppDurations.apiRequest,
    http.Client? client,
    this.onAuthError,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  /// Called when a 401 Unauthorized response is received.
  /// Used to trigger global logout flow (clear credentials, redirect to login).
  final void Function()? onAuthError;

  /// Send a POST request.
  ///
  /// [path] is appended to [baseUrl].
  /// [body] is JSON-encoded and sent with Content-Type: application/json.
  /// Returns the `data` field from the response envelope.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    return _executeRequest(
      () => _client
          .post(
            _buildUri(path),
            headers: _defaultHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout),
    );
  }

  /// Shared request executor with consistent error handling.
  Future<Map<String, dynamic>> _executeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      return _parseResponse(response);
    } on AppException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (e) {
      throw NetworkException('Koneksi timeout: ${e.message}');
    } on FormatException catch (e) {
      throw ServerException('Format respons tidak valid: ${e.message}');
    } catch (e) {
      throw ServerException('Terjadi kesalahan: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Uri _buildUri(String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath');
  }

  Map<String, String> _defaultHeaders(Map<String, String>? extra) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (extra != null) ...extra,
    };
  }

  /// Parse the API response envelope and return the [data] field.
  ///
  /// Throws the appropriate [AppException] subclass based on HTTP status code
  /// and the envelope's `status` field.
  Map<String, dynamic> _parseResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Attempt to decode the envelope
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ServerException(
        'Respons server tidak dapat dibaca (HTTP $statusCode)',
        statusCode: statusCode,
      );
    }

    final status = envelope['status'] as String?;
    final message = envelope['message'] as String? ?? 'Terjadi kesalahan';

    // 2xx with "success" envelope → return data
    if (statusCode >= 200 && statusCode < 300 && status == 'success') {
      final data = envelope['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      // If data is null or not a map, wrap it
      return {'data': data};
    }

    // Error mapping by HTTP status code
    throw _mapError(statusCode, message);
  }

  AppException _mapError(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        debugPrint('[API] HTTP 401 detected - unauthorized');
        debugPrint('[API]   Triggering auth error callback...');
        onAuthError?.call();
        return AuthException(message);
      case 403:
        return ServerException(message, statusCode: 403);
      case 404:
        return ServerException(message, statusCode: 404);
      case 500:
        return ServerException(message, statusCode: 500);
      default:
        return ServerException(message, statusCode: statusCode);
    }
  }
}
