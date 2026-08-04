// Theme configuration for Lonceng UnMan
// Generated from DESIGN.md color schemes (Material 3 with HCT algorithm)
// Implements ColorScheme light/dark from DESIGN.md section 3.2-3.3
// and custom colors (Success, fixed Navbar) via ThemeExtension

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Light mode color scheme (from DESIGN.md table 3.2)
// Light color scheme — matches HTML template colors:
// background: #FFF8F2, on-primary-container: #6D5100
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF785900),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFFC107), // Seed color yellow
  onPrimaryContainer: Color(0xFF6D5100),
  secondary: Color(0xFF745B1F),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFDB92),
  onSecondaryContainer: Color(0xFF795F23),
  tertiary: Color(0xFF006877),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFF00DEFD),
  onTertiaryContainer: Color(0xFF005E6C),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: Color(0xFFFFF8F2),
  onSurface: Color(0xFF201B11),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFEF2E1),
  surfaceContainer: Color(0xFFF8ECDB),
  surfaceContainerHigh: Color(0xFFF2E7D6),
  surfaceContainerHighest: Color(0xFFECE1D0),
  onSurfaceVariant: Color(0xFF4F4632),
  outline: Color(0xFF827660),
  outlineVariant: Color(0xFFD4C5AB),
  inverseSurface: Color(0xFF363024),
  onInverseSurface: Color(0xFFFBEFDE),
  inversePrimary: Color(0xFFFABD00),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF785900),
);

// Dark color scheme — matches HTML template colors:
// navbar-dark: #1C1B1A (surface for dark), success: #2E7D32
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFE4AF),
  onPrimary: Color(0xFF3F2E00),
  primaryContainer: Color(0xFFFFC107), // Fixed seed color yellow
  onPrimaryContainer: Color(0xFF6D5100),
  secondary: Color(0xFFE4C27C),
  onSecondary: Color(0xFF3F2E00),
  secondaryContainer: Color(0xFFFFC340),
  onSecondaryContainer: Color(0xFFD5B46F),
  tertiary: Color(0xFFB4F0FF),
  onTertiary: Color(0xFF00363F),
  tertiaryContainer: Color(0xFF00DEFD),
  onTertiaryContainer: Color(0xFF005E6C),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF181309),
  onSurface: Color(0xFFECE1D0),
  surfaceContainerLowest: Color(0xFF120E05),
  surfaceContainerLow: Color(0xFF201B11),
  surfaceContainer: Color(0xFF241F14),
  surfaceContainerHigh: Color(0xFF2F291E),
  surfaceContainerHighest: Color(0xFF3A3428),
  onSurfaceVariant: Color(0xFFD4C5AB),
  outline: Color(0xFF9C8F78),
  outlineVariant: Color(0xFF4F4632),
  inverseSurface: Color(0xFFECE1D0),
  onInverseSurface: Color(0xFF363024),
  inversePrimary: Color(0xFF785900),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFFFABD00),
);

// Custom semantic colors (from DESIGN.md section 3.4 & 3.6)
// These are not in the standard ColorScheme and must use ThemeExtension
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.navbarSurface,
    required this.onNavbarSurface,
    required this.navbarActivePill,
    required this.onNavbarActivePill,
  });

  // Success colors (DESIGN.md 3.4)
  final Color success, onSuccess, successContainer, onSuccessContainer;

  // Fixed navbar colors (DESIGN.md 3.6) — same across light/dark
  final Color navbarSurface, onNavbarSurface;
  final Color navbarActivePill, onNavbarActivePill;

  static const light = AppColors(
    success: Color(0xFF2E7D32), // From HTML template
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFA5D6A7),
    onSuccessContainer: Color(0xFF1B5E20),
    navbarSurface: Color(0xFF201B11), // Fixed: same in dark mode
    onNavbarSurface: Color(0xFFFBEFDE),
    navbarActivePill: Color(0xFFFFC107), // Primary Container
    onNavbarActivePill: Color(0xFF402D00), // On Primary Container
  );

  static const dark = AppColors(
    success: Color(0xFF7BDC78), // From HTML template
    onSuccess: Color(0xFF003909),
    successContainer: Color(0xFF005312),
    onSuccessContainer: Color(0xFF97F991),
    navbarSurface: Color(0xFF201B11), // Fixed: same in light mode
    onNavbarSurface: Color(0xFFFBEFDE),
    navbarActivePill: Color(0xFFFFC107), // Primary Container (fixed)
    onNavbarActivePill: Color(0xFF402D00), // On Primary Container (fixed)
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? navbarSurface,
    Color? onNavbarSurface,
    Color? navbarActivePill,
    Color? onNavbarActivePill,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      navbarSurface: navbarSurface ?? this.navbarSurface,
      onNavbarSurface: onNavbarSurface ?? this.onNavbarSurface,
      navbarActivePill: navbarActivePill ?? this.navbarActivePill,
      onNavbarActivePill: onNavbarActivePill ?? this.onNavbarActivePill,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      navbarSurface: Color.lerp(navbarSurface, other.navbarSurface, t)!,
      onNavbarSurface: Color.lerp(onNavbarSurface, other.onNavbarSurface, t)!,
      navbarActivePill: Color.lerp(
        navbarActivePill,
        other.navbarActivePill,
        t,
      )!,
      onNavbarActivePill: Color.lerp(
        onNavbarActivePill,
        other.onNavbarActivePill,
        t,
      )!,
    );
  }
}

// Build theme data (from DESIGN.md section 3.10)
ThemeData buildTheme(ColorScheme scheme, AppColors appColors) {
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.roboto(textStyle: base.textTheme.bodyMedium),
      bodySmall: GoogleFonts.roboto(textStyle: base.textTheme.bodySmall),
      labelLarge: GoogleFonts.roboto(textStyle: base.textTheme.labelLarge),
      labelMedium: GoogleFonts.roboto(textStyle: base.textTheme.labelMedium),
    ),
    extensions: [appColors],
  );
}

// Pre-built theme instances
final ThemeData lightTheme = buildTheme(lightColorScheme, AppColors.light);
final ThemeData darkTheme = buildTheme(darkColorScheme, AppColors.dark);
