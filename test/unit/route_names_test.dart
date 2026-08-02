// test/unit/route_names_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

void main() {
  test('RouteNames has all expected paths', () {
    expect(RouteNames.login, '/login');
    expect(RouteNames.home, '/main/home');
    expect(RouteNames.jadwal, '/main/jadwal');
    expect(RouteNames.profile, '/main/profile');
    expect(RouteNames.settings, '/main/profile/settings');
  });
}
