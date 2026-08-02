// Main entry point for Lonceng UnMan
// Initializes app with Material 3 theme and go_router navigation
// Based on DESIGN.md theme configuration (section 3.10)

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';

void main() {
  runApp(const LoncengUnmanApp());
}

class LoncengUnmanApp extends StatelessWidget {
  const LoncengUnmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.create(
      authStatusProvider: StubAuthStatusProvider(),
    );

    return MaterialApp.router(
      title: 'Lonceng UnMan',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // Default: follow system (DESIGN.md 5.4)
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
