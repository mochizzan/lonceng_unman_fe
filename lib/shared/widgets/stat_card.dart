// Shared StatCard — eliminates private _StatCard duplicates
// across quick_stats (home) and profile_bio_section (profile).

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

/// A stat card displaying a label above a value, optionally with an icon
/// badge and footnote text.
///
/// Handles both the home quick-stats variant (icon + label + RichText value)
/// and the profile bio section variant (label + value only).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.iconBg,
    this.labelColor,
    this.valueColor,
    this.footnote,
    this.footnoteColor,
    this.textScaleFactor = 1.0,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBg;
  final Color? labelColor;
  final Color? valueColor;
  final String? footnote;
  final Color? footnoteColor;

  /// Multiplier for text sizes — 1.0 for profile (smaller), >1.0 for home.
  final double textScaleFactor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final effectiveLabelColor = labelColor ?? cs.onSurfaceVariant;
    final effectiveValueColor = valueColor ?? cs.onSurface;
    final effectiveFootnoteColor = footnoteColor ?? cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius2XL),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: AppDimens.avatarSM,
              height: AppDimens.avatarSM,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: iconBg ?? cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon!,
                size: AppDimens.iconSM,
                color: iconColor ?? cs.primary,
              ),
            ),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimens.textSM * textScaleFactor,
              color: effectiveLabelColor,
            ),
          ),
          const SizedBox(height: 2),
          if (footnote != null)
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: AppDimens.text4XL * textScaleFactor,
                  fontWeight: FontWeight.bold,
                  color: effectiveValueColor,
                ),
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: footnote,
                    style: TextStyle(
                      fontSize: AppDimens.textBase * textScaleFactor,
                      fontWeight: FontWeight.w500,
                      color: effectiveFootnoteColor,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: AppDimens.textBase * textScaleFactor,
                fontWeight: FontWeight.bold,
                color: effectiveValueColor,
              ),
            ),
        ],
      ),
    );
  }
}
