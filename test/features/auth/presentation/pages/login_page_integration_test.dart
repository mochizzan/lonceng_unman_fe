// Integration test: unauthenticated user accesses /login.
// Verifies the LoginPage renders when the auth status is unauthenticated
// and the route is wrapped with BlocProvider providing AuthBloc.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';

class _FakeGetAuth implements GetAuth {
  @override
  AuthRepository get repository => throw UnimplementedError();

  @override
  Future<AuthEntity> call({required String npm}) async {
    return AuthEntity(npm: npm, token: 'fake', expiresAt: DateTime.now());
  }
}

void main() {
  setUp(() {
    Services.register<GetAuth>(_FakeGetAuth());
  });

  tearDown(() {
    Services.unregister<GetAuth>();
  });

  testWidgets('LoginPage renders on /login for unauthenticated user', (
    tester,
  ) async {
    final notifier = AuthStatusNotifier();
    final router = AppRouter.create(
      authStatusNotifier: notifier,
      themeNotifier: ThemeNotifier(),
      initialLocation: '/login',
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    // LoginPage should be visible for unauthenticated user.
    expect(find.text('Masuk Akun'), findsNWidgets(2)); // header + button
  });
}
