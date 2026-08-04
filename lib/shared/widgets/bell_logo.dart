import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

/// App logo: toga cap icon (Icons.school) in Primary Container circle, radius 28px.
class BellLogo extends StatelessWidget {
  const BellLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: sp(context, 80),
      height: sp(context, 80),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(sp(context, 28)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
            offset: Offset(0, sp(context, 4)),
            blurRadius: sp(context, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.school,
        size: sp(context, 38),
        color: cs.onPrimaryContainer,
      ),
    );
  }
}
