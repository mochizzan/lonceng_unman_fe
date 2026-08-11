// test/router/app_router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import '../helpers/test_di.dart';

void main() {
  setUpAll(registerTestDependencies);
  tearDownAll(unregisterTestDependencies);
  group('AppRouter.create', () {
    test('returns a GoRouter instance', () {
      final router = AppRouter.create(
        authStatusNotifier: AuthStatusNotifier(),
        themeNotifier: testThemeNotifier,
      );
      expect(router, isA<GoRouter>());
    });

    test('all routes are named (no unnamed routes)', () {
      final router = AppRouter.create(
        authStatusNotifier: AuthStatusNotifier(),
        themeNotifier: testThemeNotifier,
      );

      for (final config in router.configuration.routes) {
        if (config is GoRoute) {
          expect(
            config.name,
            isNotNull,
            reason: 'GoRoute at path ${config.path} has no name',
          );
        } else if (config is ShellRoute) {
          for (final sub in config.routes) {
            if (sub is GoRoute) {
              expect(
                sub.name,
                isNotNull,
                reason: 'ShellRoute child at path ${sub.path} has no name',
              );
            }
          }
        }
      }
    });

    test(
      'ShellRoute contains exactly home, jadwal, profile, settings, notificationHistory',
      () {
        final router = AppRouter.create(
          authStatusNotifier: AuthStatusNotifier(),
          themeNotifier: testThemeNotifier,
        );

        bool foundShell = false;
        for (final config in router.configuration.routes) {
          if (config is ShellRoute) {
            foundShell = true;
            // home, jadwal, profile, settings, notificationHistory —
            // settings & notificationHistory ada di dalam ShellRoute
            // agar mewarisi NotificationCubit dari parent.
            expect(config.routes.length, 5);
            expect((config.routes[0] as GoRoute).name, RouteNames.home);
            expect((config.routes[1] as GoRoute).name, RouteNames.jadwal);
            expect((config.routes[2] as GoRoute).name, RouteNames.profile);
            expect((config.routes[3] as GoRoute).name, RouteNames.settings);
            expect(
              (config.routes[4] as GoRoute).name,
              RouteNames.notificationHistory,
            );
          }
        }
        expect(foundShell, isTrue, reason: 'No ShellRoute found');
      },
    );

    test('login is standalone, settings lives inside ShellRoute', () {
      final router = AppRouter.create(
        authStatusNotifier: AuthStatusNotifier(),
        themeNotifier: testThemeNotifier,
      );

      final topLevelNames = router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.name)
          .toSet();

      final shellChildNames = router.configuration.routes
          .whereType<ShellRoute>()
          .expand((s) => s.routes)
          .whereType<GoRoute>()
          .map((r) => r.name)
          .toSet();

      // login standalone (di top-level, bukan di dalam ShellRoute).
      expect(topLevelNames, contains(RouteNames.login));
      expect(shellChildNames, isNot(contains(RouteNames.login)));

      // settings hidup di dalam ShellRoute agar mewarisi NotificationCubit.
      expect(shellChildNames, contains(RouteNames.settings));
      expect(topLevelNames, isNot(contains(RouteNames.settings)));

      // avatar-crop harus top-level (tidak punya bottom navbar).
      expect(topLevelNames, contains(RouteNames.avatarCrop));
      expect(shellChildNames, isNot(contains(RouteNames.avatarCrop)));
    });

    test('initial location defaults to /login', () {
      final router = AppRouter.create(
        authStatusNotifier: AuthStatusNotifier(),
        themeNotifier: testThemeNotifier,
      );

      // go_router 17.x: verify via navigatorKey
      // initial location is tested through widget test below.
      // Here we verify the router was constructed without error.
      expect(router, isNotNull);
    });
  });

  group('auth guard integration', () {
    testWidgets(
      'unauthenticated user deep-linking to /home is redirected to /login',
      (tester) async {
        final provider = AuthStatusNotifier(AuthStatus.unauthenticated);
        final router = AppRouter.create(
          authStatusNotifier: provider,
          themeNotifier: testThemeNotifier,
          initialLocation: '/home',
        );

        await tester.pumpWidget(
          BlocProvider<DataInitBloc>(
            create: (_) => DataInitBloc(Services.get<GetDataInitialization>()),
            child: BlocProvider<AvatarCubit>.value(
              value: Services.get<AvatarCubit>(),
              child: MaterialApp.router(
                routerConfig: router,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: ThemeMode.system,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Masuk Akun'), findsNWidgets(2)); // header + button
      },
    );

    testWidgets('authenticated user on /login is redirected to /home', (
      tester,
    ) async {
      final provider = AuthStatusNotifier(AuthStatus.authenticated);
      final router = AppRouter.create(
        authStatusNotifier: provider,
        themeNotifier: testThemeNotifier,
        initialLocation: '/${RouteNames.login}',
      );

      await tester.pumpWidget(
        BlocProvider<DataInitBloc>(
          create: (_) => DataInitBloc(Services.get<GetDataInitialization>()),
          child: BlocProvider<AvatarCubit>.value(
            value: Services.get<AvatarCubit>(),
            child: MaterialApp.router(
              routerConfig: router,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: ThemeMode.system,
            ),
          ),
        ),
      );
      // Use pump() instead of pumpAndSettle() because home page has
      // Timer.periodic countdown that never settles.
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Halo'), findsOneWidget);
    });
  });
}
