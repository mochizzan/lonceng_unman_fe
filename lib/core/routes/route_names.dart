// RouteNames: centralized route path constants.
//
// Centralizing route strings in one place prevents drift and typos when paths
// change. Every route literal should reference these constants rather than its
// raw path string.
class RouteNames {
  RouteNames._();

  static const String login = '/login';
  static const String home = '/main/home';
  static const String jadwal = '/main/jadwal';
  static const String profile = '/main/profile';
  static const String settings = '/main/profile/settings';
}
