// lib/core/routes/app_router.dart
//
// Route configuration using go_router.
// Defines all app routes based on DESIGN.md navigation structure.
//
// Post-login flow: authenticated users go straight to /home.
// Data initialization runs at login time; home shows skeletons while
// cache data loads.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';

import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/pages/data_initialization_page.dart';
import 'package:lonceng_unman_fe/features/home/presentation/pages/home_page.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/profile_page.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/pages/settings_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Auth guard redirect logic. Returns a redirect path or null (no redirect).
///
/// [matchedRoute] is the route's name (obtained from state.topRoute?.name).
/// This is a pure function — no GoRouterState dependency — for testability.
String? authRedirect(
  String? matchedRoute,
  AuthStatusProvider authStatusProvider,
) {
  final status = authStatusProvider.currentStatus;

  // Unknown: let routing proceed; pages show loading state.
  if (status == AuthStatus.unknown) return null;

  final isLogin = matchedRoute == RouteNames.login;
  final isDataInit = matchedRoute == RouteNames.dataInit;

  // Unauthenticated: block everything except /login.
  if (status == AuthStatus.unauthenticated) {
    return isLogin ? null : '/${RouteNames.login}';
  }

  // Authenticated: leave login and the legacy data-init gate.
  // Data-init runs in the background on the home shell.
  if (isLogin || isDataInit) return '/${RouteNames.home}';

  return null; // authenticated + app route → allow
}

/// Converts a [Stream] into a [Listenable] for go_router 17.x.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

int _indexForRoute(String? routeName) {
  switch (routeName) {
    case RouteNames.home:
      return 0;
    case RouteNames.jadwal:
      return 1;
    case RouteNames.profile:
      return 2;
    default:
      return 0;
  }
}

List<RouteBase> _buildRoutes(
  AuthStatusNotifier authStatusNotifier,
  ThemeNotifier themeNotifier,
) {
  return <RouteBase>[
    // --- Auth (standalone, no bottom nav) ---
    GoRoute(
      name: RouteNames.login,
      path: '/${RouteNames.login}',
      builder: (context, state) =>
          LoginPage(authStatusNotifier: authStatusNotifier),
    ),

    // --- Legacy data-init (redirects to home; pipeline is background) ---
    GoRoute(
      name: RouteNames.dataInit,
      path: '/${RouteNames.dataInit}',
      builder: (context, state) => const DataInitializationPage(),
    ),

    // --- Main app (bottom navigation shell) ---
    ShellRoute(
      builder: (context, state, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => NotificationCubit(
                scheduler: Services.get<NotificationScheduler>(),
                repository: Services.get<NotificationRepository>(),
                notificationService: Services.get<NotificationService>(),
              )..loadNotifications(),
            ),
          ],
          child: MainShellScaffold(
            currentIndex: _indexForRoute(state.topRoute?.name),
            child: child,
          ),
        );
      },
      routes: <RouteBase>[
        GoRoute(
          name: RouteNames.home,
          path: '/${RouteNames.home}',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          name: RouteNames.jadwal,
          path: '/${RouteNames.jadwal}',
          builder: (context, state) => const JadwalPage(),
        ),
        GoRoute(
          name: RouteNames.profile,
          path: '/${RouteNames.profile}',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                ProfileBloc(Services.get<GetProfile>())
                  ..add(const ProfileFetchRequested()),
            child: const ProfilePage(),
          ),
        ),
      ],
    ),

    // --- Onboarding (first-time users) ---
    GoRoute(
      name: RouteNames.onboarding,
      path: RouteNames.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),

    // --- Settings (standalone; accessible from Profile via pushNamed) ---
    GoRoute(
      name: RouteNames.settings,
      path: '/${RouteNames.settings}',
      builder: (context, state) => BlocProvider(
        create: (_) => NotificationCubit(
          scheduler: Services.get<NotificationScheduler>(),
          repository: Services.get<NotificationRepository>(),
          notificationService: Services.get<NotificationService>(),
        )..loadNotifications(),
        child: SettingsPage(notifier: themeNotifier),
      ),
    ),
  ];
}

final class AppRouter {
  AppRouter._();

  static GoRouter create({
    required AuthStatusNotifier authStatusNotifier,
    required ThemeNotifier themeNotifier,
    String initialLocation = '/${RouteNames.login}',
    List<NavigatorObserver>? observers,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: _StreamListenable(authStatusNotifier.status),
      redirect: (context, state) {
        // First-time users must complete onboarding
        final onboardingRepo = Services.get<OnboardingRepository>();
        if (!onboardingRepo.isCompleted &&
            state.matchedLocation != RouteNames.onboarding) {
          return RouteNames.onboarding;
        }
        return authRedirect(state.topRoute?.name, authStatusNotifier);
      },
      routes: _buildRoutes(authStatusNotifier, themeNotifier),
      errorBuilder: (context, state) {
        return AppErrorPage(state: state);
      },
      observers: observers ?? [],
      debugLogDiagnostics: false,
    );
  }
}
