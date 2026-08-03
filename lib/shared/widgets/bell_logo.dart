import 'dart:math' as math;

import 'package:flutter/material.dart';

/// App logo: bell icon in Primary Container circle, radius 28px, tilted 3deg.
class BellLogo extends StatelessWidget {
  const BellLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Transform.rotate(
      angle: 3 * math.pi / 180,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          Icons.notifications_none,
          size: 38,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
