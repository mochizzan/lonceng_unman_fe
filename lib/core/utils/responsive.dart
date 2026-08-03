// Shared responsive utilities for scaling dimensions.
// Baseline 375px (iPhone width), clamped 0.85–1.15 for layout,
// and textScaleFactor clamped 0.85–1.3 for font sizes.
import 'package:flutter/widgets.dart';

/// Scale factor based on screen width (baseline 375px).
double scale(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return (1 - (375 - width) / 1000).clamp(0.85, 1.15);
}

/// Scale a dimension by [scale].
double sp(BuildContext context, double value) => value * scale(context);

/// Font size that scales with screen width AND respects textScaleFactor.
double responsiveFontSize(BuildContext context, double baseSize) {
  final s = scale(context);
  final textScaler = MediaQuery.textScalerOf(context);
  final textScale = textScaler.scale(1.0);
  return baseSize * s * textScale.clamp(0.85, 1.3);
}
