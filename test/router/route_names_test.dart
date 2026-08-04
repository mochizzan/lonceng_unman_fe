// test/router/route_names_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

void main() {
  test('RouteNames contains all 5 required routes', () {
    expect(RouteNames.login, 'login');
    expect(RouteNames.home, 'home');
    expect(RouteNames.jadwal, 'jadwal');
    expect(RouteNames.profile, 'profile');
    expect(RouteNames.settings, 'settings');
  });

  test('RouteNames does not contain slashes', () {
    for (final name in [
      RouteNames.login,
      RouteNames.home,
      RouteNames.jadwal,
      RouteNames.profile,
      RouteNames.settings,
    ]) {
      expect(name.contains('/'), isFalse, reason: '$name contains a slash');
    }
  });

  test('RouteNames cannot be instantiated', () {
    expect(() => RouteNames(), throwsA(isA<TypeError>()));
  });
}
