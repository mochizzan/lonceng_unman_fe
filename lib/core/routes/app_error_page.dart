// lib/core/routes/app_error_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

/// Material 3 error page for 404 / unknown-route errors.
/// Shows a bell icon (Lonceng brand motif) and a "back to home" button.
class AppErrorPage extends StatelessWidget {
  const AppErrorPage({super.key, this.state});

  final GoRouterState? state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'Halaman Tidak Ditemukan',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (state?.error?.toString().isNotEmpty ?? false)
                Text(
                  state!.error.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final goRouter = GoRouter.maybeOf(context);
                  if (goRouter != null) {
                    context.goNamed(RouteNames.home);
                  } else {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed('/${RouteNames.home}');
                  }
                },
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
