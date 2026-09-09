import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

/// Returns true when [error] represents a connectivity failure that should
/// pause the fresh-login pipeline (Retry / Skip) rather than being swallowed.
///
/// Network sources: [NetworkException], [TimeoutException],
/// [SocketException], [HandshakeException], [HttpException], [IOException],
/// [http.ClientException], and [DataInitStepException] wrapping any of them.
/// A [failedStep] of `'no_connection'` or `'timeout'` is also treated as network.
bool isNetworkError(Object error, {String? failedStep}) {
  if (failedStep == 'no_connection' || failedStep == 'timeout') return true;
  if (error is NetworkException) return true;
  if (error is TimeoutException) return true;
  if (error is SocketException) return true;
  if (error is HandshakeException) return true;
  if (error is HttpException) return true;
  if (error is IOException) return true;
  if (error is http.ClientException) return true;
  if (error is DataInitStepException) {
    final orig = error.originalError;
    if (orig is NetworkException) return true;
    if (orig is TimeoutException) return true;
    if (orig is SocketException) return true;
    if (orig is HandshakeException) return true;
    if (orig is HttpException) return true;
    if (orig is IOException) return true;
    if (orig is http.ClientException) return true;
  }
  return false;
}

/// Returns true for mandatory profile steps — those must not offer Skip.
bool isProfileStep(String step) => step.startsWith('profile');
