// Shared responsive utilities for scaling dimensions.
// Baseline 375px (iPhone width), clamped 0.85–1.15 for layout,
// and textScaleFactor clamped 0.85–1.3 for font sizes.
import 'package:flutter/widgets.dart';
import 'package:lonceng_unman_fe/core/constants/app_dimens.dart';

/// Scale factor based on screen width (baseline 375px).
double scale(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return (1 -
          (AppDimens.responsiveBaseline - width) / AppDimens.responsiveDivisor)
      .clamp(AppDimens.responsiveClampLow, AppDimens.responsiveClampHigh);
}

/// Scale a dimension by [scale].
double sp(BuildContext context, double value) => value * scale(context);

/// Font size that scales with screen width AND respects textScaleFactor.
double responsiveFontSize(BuildContext context, double baseSize) {
  final s = scale(context);
  final textScaler = MediaQuery.textScalerOf(context);
  final textScale = textScaler.scale(1.0);
  return baseSize *
      s *
      textScale.clamp(
        AppDimens.textScaleClampLow,
        AppDimens.textScaleClampHigh,
      );
}
