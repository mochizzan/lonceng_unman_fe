// profile - Action button widget
//
// "Perbarui Data Terbaru" full-width tonal button (DESIGN.md §5.4:
// Secondary Container / On Secondary Container, radius 24).
// Layout matches the HTML template: a full-width FilledButton with
// tonal style wrapping an Icon(refresh) + Text row.

import 'package:flutter/material.dart';

/// Full-width tonal action button for refreshing academic profile data.
///
/// Uses `Secondary Container` / `On Secondary Container` colors via
/// [Theme.of] (no hardcoded colors) with a 24px radius,
/// per DESIGN.md §5.4 and the HTML template layout.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.refresh),
            SizedBox(width: 8),
            Text(
              'Perbarui Data Terbaru',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
