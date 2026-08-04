// lib/core/constants/app_dimens.dart
/// Centralized dimension tokens for spacing, sizing, and layout.
///
/// All magic numbers in widgets should reference these constants.
/// Organized by category for easy discovery.
abstract final class AppDimens {
  // ─── Spacing (base unit: 4px) ─────────────────────────
  static const double space0 = 0;
  static const double space1 = 1;
  static const double space2 = 2;
  static const double space3 = 3;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space36 = 36;
  static const double space40 = 40;
  static const double space44 = 44;
  static const double space48 = 48;
  static const double space52 = 52;
  static const double space80 = 80;
  static const double space96 = 96;
  static const double space112 = 112;

  // ─── Font Sizes ───────────────────────────────────────
  static const double textXS = 11;
  static const double textSM = 12;
  static const double textBase = 13;
  static const double textMD = 14;
  static const double textLG = 15;
  static const double textXL = 16;
  static const double text2XL = 18;
  static const double text3XL = 19;
  static const double text4XL = 20;
  static const double text5XL = 22;
  static const double text6XL = 24;
  static const double textHero = 44;

  // ─── Border Radius ────────────────────────────────────
  static const double radiusXS = 2;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radius2XL = 22;
  static const double radius3XL = 24;
  static const double radius4XL = 32;
  static const double radiusFull = 999;

  // ─── Icon Sizes ───────────────────────────────────────
  static const double iconSM = 18;
  static const double iconMD = 20;
  static const double iconLG = 26;
  static const double iconXL = 36;
  static const double icon2XL = 44;
  static const double iconError = 48;

  // ─── Dot Sizes ────────────────────────────────────────
  static const double dotXS = 6;
  static const double dotSM = 8;
  static const double dotMD = 10;
  static const double dotLG = 14;
  static const double dotXL = 20;

  // ─── Avatar Sizes ─────────────────────────────────────
  static const double avatarSM = 36;
  static const double avatarMD = 44;
  static const double avatarLG = 96;
  static const double avatarXL = 112;

  // ─── Navbar Dimensions ────────────────────────────────
  static const double navBarHeight = 64;
  static const double navBarWidth = 280;
  static const double navBarItemWidth = 64;
  static const double navBarItemHeight = 56;
  static const double navBarPillWidth = 52;
  static const double navBarPillHeight = 44;
  static const double navBarMarginBottom = 20;
  static const double navBarMarginHorizontal = 24;
  static const double navBarPaddingVertical = 12;
  static const double navBarPaddingHorizontal = 8;

  // ─── Card Dimensions ──────────────────────────────────
  static const double cardHeroRadius = 32;
  static const double cardItemRadius = 20;
  static const double cardStatRadius = 20;

  // ─── Shadow ───────────────────────────────────────────
  static const double shadowOffsetY = 3;
  static const double shadowBlurRadius = 10;
  static const double shadowNavBarOffsetY = 8;
  static const double shadowNavBarBlurRadius = 20;

  // ─── Border Width ─────────────────────────────────────
  static const double borderWidthThin = 1;
  static const double borderWidthMedium = 2;

  // ─── Letter Spacing ───────────────────────────────────
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0;
  static const double letterSpacingWide = 0.5;

  // ─── Screen Padding ───────────────────────────────────
  static const double screenPaddingHorizontal = 20;
  static const double screenPaddingVertical = 24;

  // ─── Responsive Breakpoints ───────────────────────────
  static const double responsiveBaseline = 375;
  static const double responsiveDivisor = 1000;
  static const double responsiveClampLow = 0.85;
  static const double responsiveClampHigh = 1.15;
  static const double textScaleClampLow = 0.85;
  static const double textScaleClampHigh = 1.3;
}
