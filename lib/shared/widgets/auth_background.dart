import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

/// Background gradient: Surface -> Primary Container with decorative blobs.
/// Uses theme-derived colorScheme values (DESIGN.md §5.1).
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
            top: sp(context, -96),
            right: sp(context, -64),
            child: Container(
              width: sp(context, 224),
              height: sp(context, 224),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: sp(context, -80),
            left: sp(context, -64),
            child: Container(
              width: sp(context, 224),
              height: sp(context, 224),
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
