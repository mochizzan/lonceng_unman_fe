// lib/core/network/api_client.dart
library;

/// Base HTTP client for API communication.
///
/// This is a placeholder implementation. Replace with a real HTTP client
/// (dio, http, etc.) when the backend is available.
///
/// All API calls should go through this client to ensure consistent
/// error handling, timeout configuration, and interceptors.
import 'dart:async';

import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

/// Base API client for HTTP communication.
///
/// Provides configurable base URL, timeout, and error handling.
/// Extend this class or use it directly for simple API calls.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  final String baseUrl;
  final Duration timeout;

  /// Send a GET request.
  ///
  /// [path] is appended to [baseUrl].
  /// Returns the response body as a Map.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    // TODO: Implement real HTTP client
    throw const NetworkException(
      'API client not implemented. Replace with real HTTP client.',
    );
  }

  /// Send a POST request.
  ///
  /// [path] is appended to [baseUrl].
  /// [body] is sent as JSON.
  /// Returns the response body as a Map.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    // TODO: Implement real HTTP client
    throw const NetworkException(
      'API client not implemented. Replace with real HTTP client.',
    );
  }
}
