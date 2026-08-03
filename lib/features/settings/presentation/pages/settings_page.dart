// lib/features/settings/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/widgets/settings_widgets.dart';

/// Settings page — surfaces theme & reminder controls from DESIGN.md §5.4.
/// Accessed from Profile via context.pushNamed(RouteNames.settings).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema Aplikasi'),
            trailing: const ThemeSegmentedControl(),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Ingatkan Sebelum Kelas'),
            subtitle: const Text('5 menit'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('Versi Aplikasi', style: theme.textTheme.bodyMedium),
            subtitle: const Text('1.0.0+1'),
          ),
        ],
      ),
    );
  }
}
