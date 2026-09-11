// lib/core/errors/app_errors.dart
/// Base exception class for all app-specific errors.
///
/// All domain/data layer exceptions should extend [AppException].
/// This provides a consistent error handling pattern across the app.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType($message)';
}

/// Network-related errors (no internet, timeout, DNS failure).
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code = 'NETWORK_ERROR'});
}

/// Server returned an error response (4xx, 5xx).
final class ServerException extends AppException {
  const ServerException(
    super.message, {
    super.code = 'SERVER_ERROR',
    this.statusCode,
  });

  final int? statusCode;
}

/// Authentication errors (invalid credentials, expired token).
final class AuthException extends AppException {
  const AuthException(super.message, {super.code = 'AUTH_ERROR'});
}

/// Validation errors (invalid input, missing required fields).
final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code = 'VALIDATION_ERROR'});
}

/// Alumni-specific 409 — BE gate `hasAlumniKRS` for `POST /krs/data`.
/// Distinguishes ALUMNI from generic 4xx/5xx to allow cache invalidation.
final class AlumniException extends AppException {
  const AlumniException(
    super.message, {
    super.code = 'ALUMNI_ERROR',
    this.statusCode = 409,
  });

  final int statusCode;
}

/// Helper to check alumni error via type or 409 status.
bool isAlumniError(Object e) =>
    e is AlumniException ||
    (e is ServerException && e.statusCode == 409) ||
    (e is AppException && (e as dynamic).statusCode == 409);

/// Exception thrown when a pipeline step in data initialization fails.
/// Carries the step name and original error for diagnostics.
final class DataInitStepException extends AppException {
  const DataInitStepException(this.step, super.message, [this.originalError]);

  final String step;
  final Object? originalError;

  @override
  String toString() => 'DataInitStepException($step): $message';
}
