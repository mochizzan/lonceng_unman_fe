import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff6e5d0e),
      surfaceTint: Color(0xff6e5d0e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xfffae287),
      onPrimaryContainer: Color(0xff544600),
      secondary: Color(0xff675e40),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffefe2bc),
      onSecondaryContainer: Color(0xff4e472a),
      tertiary: Color(0xff44664e),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc5eccd),
      onTertiaryContainer: Color(0xff2c4e37),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff9ee),
      onSurface: Color(0xff1e1b13),
      onSurfaceVariant: Color(0xff4b4739),
      outline: Color(0xff7c7767),
      outlineVariant: Color(0xffcdc6b4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff333027),
      inversePrimary: Color(0xffdcc66e),
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
      surfaceDim: Color(0xffe0d9cc),
      surfaceBright: Color(0xfffff9ee),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffaf3e5),
      surfaceContainer: Color(0xfff4eddf),
      surfaceContainerHigh: Color(0xffeee7da),
      surfaceContainerHighest: Color(0xffe9e2d4),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff413500),
      surfaceTint: Color(0xff6e5d0e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff7e6c1e),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3d361b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff766d4d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff1b3d28),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff52755c),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff9ee),
      onSurface: Color(0xff131109),
      onSurfaceVariant: Color(0xff3a3629),
      outline: Color(0xff575244),
      outlineVariant: Color(0xff726d5e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff333027),
      inversePrimary: Color(0xffdcc66e),
      primaryFixed: Color(0xff7e6c1e),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff645402),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff766d4d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff5d5537),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff52755c),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff3a5c45),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffccc6b9),
      surfaceBright: Color(0xfffff9ee),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffaf3e5),
      surfaceContainer: Color(0xffeee7da),
      surfaceContainerHigh: Color(0xffe3dccf),
      surfaceContainerHighest: Color(0xffd7d1c4),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff352b00),
      surfaceTint: Color(0xff6e5d0e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff574800),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff322c12),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff51492c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff10321e),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff2f503a),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff9ee),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff302c20),
      outlineVariant: Color(0xff4d493b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff333027),
      inversePrimary: Color(0xffdcc66e),
      primaryFixed: Color(0xff574800),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff3d3200),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff51492c),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff393218),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff2f503a),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff183924),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbeb8ab),
      surfaceBright: Color(0xfffff9ee),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f0e2),
      surfaceContainer: Color(0xffe9e2d4),
      surfaceContainerHigh: Color(0xffdad4c6),
      surfaceContainerHighest: Color(0xffccc6b9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
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

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff3dc81),
      surfaceTint: Color(0xffdcc66e),
      onPrimary: Color(0xff2e2500),
      primaryContainer: Color(0xffa4903e),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffe8dcb6),
      onSecondary: Color(0xff2c250c),
      secondaryContainer: Color(0xff9a906f),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbfe6c7),
      onTertiary: Color(0xff092c18),
      tertiaryContainer: Color(0xff75997e),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff16130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe4dcc9),
      outline: Color(0xffb8b1a0),
      outlineVariant: Color(0xff969080),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e2d4),
      inversePrimary: Color(0xff554700),
      primaryFixed: Color(0xfffae287),
      onPrimaryFixed: Color(0xff161100),
      primaryFixedDim: Color(0xffdcc66e),
      onPrimaryFixedVariant: Color(0xff413500),
      secondaryFixed: Color(0xffefe2bc),
      onSecondaryFixed: Color(0xff161100),
      secondaryFixedDim: Color(0xffd2c6a1),
      onSecondaryFixedVariant: Color(0xff3d361b),
      tertiaryFixed: Color(0xffc5eccd),
      onTertiaryFixed: Color(0xff001508),
      tertiaryFixedDim: Color(0xffaad0b2),
      onTertiaryFixedVariant: Color(0xff1b3d28),
      surfaceDim: Color(0xff16130b),
      surfaceBright: Color(0xff48443a),
      surfaceContainerLowest: Color(0xff090703),
      surfaceContainerLow: Color(0xff201d15),
      surfaceContainer: Color(0xff2b281f),
      surfaceContainerHigh: Color(0xff353229),
      surfaceContainerHighest: Color(0xff413d34),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffff0bd),
      surfaceTint: Color(0xffdcc66e),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffd8c26b),
      onPrimaryContainer: Color(0xff0f0b00),
      secondary: Color(0xfffcf0c9),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffcec29e),
      onSecondaryContainer: Color(0xff0f0b00),
      tertiary: Color(0xffd3fada),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffa6ccae),
      onTertiaryContainer: Color(0xff000f05),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff16130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff8efdd),
      outlineVariant: Color(0xffc9c2b0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e2d4),
      inversePrimary: Color(0xff554700),
      primaryFixed: Color(0xfffae287),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffdcc66e),
      onPrimaryFixedVariant: Color(0xff161100),
      secondaryFixed: Color(0xffefe2bc),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffd2c6a1),
      onSecondaryFixedVariant: Color(0xff161100),
      tertiaryFixed: Color(0xffc5eccd),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffaad0b2),
      onTertiaryFixedVariant: Color(0xff001508),
      surfaceDim: Color(0xff16130b),
      surfaceBright: Color(0xff545046),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff221f17),
      surfaceContainer: Color(0xff333027),
      surfaceContainerHigh: Color(0xff3f3b32),
      surfaceContainerHighest: Color(0xff4a473d),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
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
