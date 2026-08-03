// lib/features/settings/presentation/widgets/settings_widgets.dart
import 'package:flutter/material.dart';

/// Placeholder for theme segmented control (Light / Dark / System).
/// Replace with real ThemeMode state management when theme switching is implemented.
class ThemeSegmentedControl extends StatelessWidget {
  const ThemeSegmentedControl({super.key});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment<int>(value: 0, label: Text('Light')),
        ButtonSegment<int>(value: 1, label: Text('Dark')),
        ButtonSegment<int>(value: 2, label: Text('Auto')),
      ],
      selected: const <int>{2},
    );
  }
}
