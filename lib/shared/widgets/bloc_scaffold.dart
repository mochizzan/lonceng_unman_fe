// Shared BLoC loading/error widgets — eliminates 3 private _buildLoading
// and 3 private _buildError duplicates across home, jadwal, and profile pages.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

/// Standard error display used by all BLoC-driven pages.
///
/// Shows an error icon, message text, and optionally a retry button.
class AppErrorDisplay extends StatelessWidget {
  const AppErrorDisplay({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: AppDimens.iconError, color: cs.error),
          const SizedBox(height: AppDimens.space16),
          Text(message, style: TextStyle(color: cs.onSurface)),
          if (onRetry != null) ...[
            const SizedBox(height: AppDimens.space16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ],
      ),
    );
  }
}
