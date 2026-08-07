// Shared widgets
// Add reusable widget components here (buttons, cards, etc.)

import 'package:flutter/material.dart';

/// Filled button — radius 24px, full-width when [fullWidth] is true.
///
/// Default variant uses Primary Container / On Primary Container.
/// Set [secondary] to true for Secondary Container / On Secondary Container.
/// (DESIGN.md §6 — Filled Button)
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.fullWidth = false,
    this.secondary = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool fullWidth;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary
            ? cs.secondaryContainer
            : cs.primaryContainer,
        foregroundColor: secondary
            ? cs.onSecondaryContainer
            : cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: child,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
