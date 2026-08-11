import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

/// Centralized error handler that converts technical exceptions into
/// human-readable Indonesian messages and displays them as Toasts.
class ErrorHandler {
  /// Show a user-friendly error toast.
  static void show(BuildContext context, Object error) {
    final message = toHumanReadable(error);
    debugPrint('[ErrorHandler] show: $message (original: $error)');
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
    );
  }

  /// Convert a technical error to a human-readable Indonesian message.
  static String toHumanReadable(Object error) {
    if (error is NetworkException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    if (error is ValidationException) {
      return error.message;
    }
    if (error is ServerException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'Koneksi timeout. Silakan coba lagi.';
    }
    if (error is DataInitStepException) {
      return _pipelineError(error);
    }
    return error.toString();
  }

  static String _pipelineError(DataInitStepException error) {
    return error.message;
  }
}
