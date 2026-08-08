// lib/core/routes/app_error_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppDimens.space24),
              Text(
                AppStrings.errorNotFound,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.space8),
              Text(
                AppStrings.errorNotFoundDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (state?.error?.toString().isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state!.error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: AppDimens.space24),
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
                child: const Text(AppStrings.errorBackToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
