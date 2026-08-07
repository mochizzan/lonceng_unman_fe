import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

/// Legacy route kept for deep-link / old navigation compatibility.
///
/// Data initialization now runs in the background on the main shell
/// ([DataInitShellHost]). This page immediately redirects to home so
/// users are never stuck on a full-screen loading gate.
class DataInitializationPage extends StatefulWidget {
  const DataInitializationPage({super.key, this.npm, this.password});

  /// Unused — credentials are read from [CredentialCache] by the shell host.
  final String? npm;
  final String? password;

  @override
  State<DataInitializationPage> createState() => _DataInitializationPageState();
}

class _DataInitializationPageState extends State<DataInitializationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(RouteNames.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
