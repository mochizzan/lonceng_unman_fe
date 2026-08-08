import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

/// Mixin providing shared error handling for BLoCs.
mixin BlocErrorHandler {
  String handleError(Object error) {
    if (error is AuthException) {
      throw error;
    }
    if (error is NetworkException) {
      return 'Tidak ada koneksi internet. Silakan coba lagi.';
    }
    if (error is ServerException) {
      return 'Server sedang tidak tersedia. Silakan coba lagi nanti.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
