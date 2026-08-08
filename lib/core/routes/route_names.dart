/// Named route constants — single source of truth for all route names.
/// Replaces hardcoded string paths in context.go() calls.
class RouteNames {
  // RouteNames is a constant utility class — do not instantiate.
  // Throwing [TypeError] at runtime mirrors the pattern used by
  // [AuthStatusProvider] (see auth_status.dart), keeping this type
  // instantiable at the language level while failing loudly if someone
  // attempts direct construction.
  factory RouteNames() => throw TypeError();

  static const login = 'login';
  static const home = 'home';
  static const jadwal = 'jadwal';
  static const profile = 'profile';
  static const settings = 'settings';
  static const khs = 'khs';
  static const String onboarding = 'onboarding';
}
