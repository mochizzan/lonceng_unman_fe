// Shared BoxShadow patterns — eliminates duplicated shadow definitions
// across bell_logo, login_page, profile_header_card, and academic_info_section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

/// Centralized shadow definitions matching the app's design system.
class AppShadows {
  AppShadows._();

  /// Standard card shadow: [0, 4, 12, 6% opacity].
  /// Used by jadwal_card, academic_info_section.
  static List<BoxShadow> card(ColorScheme cs) {
    return [
      BoxShadow(
        color: cs.shadow.withValues(alpha: ColorValues.shadowLow),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Card shadow with responsive offset.
  /// Used by bell_logo, login_page, profile_header_card (files using sp()).
  static List<BoxShadow> cardResponsive(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return [
      BoxShadow(
        color: cs.shadow.withValues(alpha: ColorValues.shadowLow),
        offset: Offset(0, sp(context, 4)),
        blurRadius: sp(context, 12),
      ),
    ];
  }
}
