import 'package:flutter/material.dart';

/// Background gradient: Surface -> Primary Container with decorative blobs.
/// Primary Container is fixed (#FFC107) across themes (DESIGN.md §5.1).
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.surface, cs.primaryContainer.withValues(alpha: 0.15)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -96,
            right: -64,
            child: Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -64,
            child: Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.40),
                shape: BoxShape.circle,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
