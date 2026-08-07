import "package:flutter/material.dart";

class MaterialTheme {
  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff6e5d0e),
      surfaceTint: Color(0xff6e5d0e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff998a2e),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff5b5434),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff918a67),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff3a6a4d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff6b9d7d),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff900013),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffd13b2b),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff9ee),
      onSurface: Color(0xff1e1b13),
      onSurfaceVariant: Color(0xff4b4739),
      outline: Color(0xff686354),
      outlineVariant: Color(0xff969080),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff333027),
      inversePrimary: Color(0xffdcc66e),
      primaryFixed: Color(0xff998a2e),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff6e5d0e),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff918a67),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff5b5434),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff6b9d7d),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff3a6a4d),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffddd8cc),
      surfaceBright: Color(0xfffff9ee),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2e6),
      surfaceContainer: Color(0xfff1ece0),
      surfaceContainerHigh: Color(0xffebe7db),
      surfaceContainerHighest: Color(0xffe5e0d5),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffdcc66e),
      surfaceTint: Color(0xffdcc66e),
      onPrimary: Color(0xff3a3000),
      primaryContainer: Color(0xff544600),
      onPrimaryContainer: Color(0xfffae287),
      secondary: Color(0xffd2c6a1),
      onSecondary: Color(0xff373016),
      secondaryContainer: Color(0xff4e472a),
      onSecondaryContainer: Color(0xffefe2bc),
      tertiary: Color(0xffaad0b2),
      onTertiary: Color(0xff153722),
      tertiaryContainer: Color(0xff2c4e37),
      onTertiaryContainer: Color(0xffc5eccd),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff16130b),
      onSurface: Color(0xffe9e2d4),
      onSurfaceVariant: Color(0xffcdc6b4),
      outline: Color(0xff969080),
      outlineVariant: Color(0xff4b4739),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e2d4),
      inversePrimary: Color(0xff6e5d0e),
      primaryFixed: Color(0xfffae287),
      onPrimaryFixed: Color(0xff221b00),
      primaryFixedDim: Color(0xffdcc66e),
      onPrimaryFixedVariant: Color(0xff544600),
      secondaryFixed: Color(0xffefe2bc),
      onSecondaryFixed: Color(0xff211b04),
      secondaryFixedDim: Color(0xffd2c6a1),
      onSecondaryFixedVariant: Color(0xff4e472a),
      tertiaryFixed: Color(0xffc5eccd),
      onTertiaryFixed: Color(0xff00210f),
      tertiaryFixedDim: Color(0xffaad0b2),
      onTertiaryFixedVariant: Color(0xff2c4e37),
      surfaceDim: Color(0xff16130b),
      surfaceBright: Color(0xff3c3930),
      surfaceContainerLowest: Color(0xff100e07),
      surfaceContainerLow: Color(0xff1e1b13),
      surfaceContainer: Color(0xff221f17),
      surfaceContainerHigh: Color(0xff2d2a21),
      surfaceContainerHighest: Color(0xff38352b),
    );
  }
}

// ---------------------------------------------------------------------------
// AppColors ThemeExtension — custom semantic tokens (DESIGN.md 3.4 & 3.6)
// Migrated from app_theme.dart
// ---------------------------------------------------------------------------

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
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFA5D6A7),
    onSuccessContainer: Color(0xFF1B5E20),
    navbarSurface: Color(0xFF201B11),
    onNavbarSurface: Color(0xFFFBEFDE),
    navbarActivePill: Color(0xFFFFC107),
    onNavbarActivePill: Color(0xFF402D00),
  );

  static const dark = AppColors(
    success: Color(0xFF7BDC78),
    onSuccess: Color(0xFF003909),
    successContainer: Color(0xFF005312),
    onSuccessContainer: Color(0xFF97F991),
    navbarSurface: Color(0xFF201B11),
    onNavbarSurface: Color(0xFFFBEFDE),
    navbarActivePill: Color(0xFFFFC107),
    onNavbarActivePill: Color(0xFF402D00),
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

// ---------------------------------------------------------------------------
// Convenience theme getters — backward-compatible with app_theme.dart API
// ---------------------------------------------------------------------------

ThemeData get lightTheme {
  final colorScheme = MaterialTheme.lightScheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    extensions: [AppColors.light],
  );
}

ThemeData get darkTheme {
  final colorScheme = MaterialTheme.darkScheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    extensions: [AppColors.dark],
  );
}
