// lib/core/routes/app_router.dart
//
// Route configuration using go_router.
// Defines all app routes based on DESIGN.md navigation structure.
//
// Route Inventory (minimum 5 required):
// - /login → LoginPage (auth flow, standalone)
// - /home → HomePage (ShellRoute child, bottom nav)
// - /jadwal → JadwalPage (ShellRoute child, bottom nav)
// - /profile → ProfilePage (ShellRoute child, bottom nav)
// - /settings → SettingsPage (standalone, not in bottom nav)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';

// Import feature pages
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/home/presentation/pages/home_page.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/profile_page.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/pages/settings_page.dart';

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

  // Unauthenticated: block everything except /login.
  if (status == AuthStatus.unauthenticated) {
    return isLogin ? null : '/${RouteNames.login}';
  }

  // Authenticated: redirect away from /login to home.
  if (isLogin) return '/${RouteNames.home}';

  return null; // authenticated + not on login → allow
}

/// Converts a [Stream] into a [Listenable] for go_router 17.x.
/// go_router 17.x removed GoRouterRefreshSink/GoRouterRefreshStream;
/// this adapter provides the same behavior: listen to the stream and
/// notify listeners on each event so GoRouter re-evaluates redirect.
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

/// Maps a matched route name to a bottom-nav index.
/// Returns 0 (Home) for any route outside the shell — safe fallback.
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

/// Top-level route definitions.
/// The [ShellRoute] wraps the three bottom-navigation children:
/// home, jadwal, profile. /login and /settings are standalone.
final List<RouteBase> appRoutes = <RouteBase>[
  // --- Auth (standalone, no bottom nav) ---
  GoRoute(
    name: RouteNames.login,
    path: '/${RouteNames.login}',
    builder: (context, state) => BlocProvider(
      create: (_) => AuthBloc(
        GetAuth(
          AuthRepositoryImpl(remoteDataSource: StubAuthRemoteDataSource()),
        ),
      ),
      child: const LoginPage(),
    ),
  ),

  // --- Main app (bottom navigation shell) ---
  ShellRoute(
    builder: (context, state, child) {
      return MainShellScaffold(
        currentIndex: _indexForRoute(state.topRoute?.name),
        child: child,
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
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  ),

  // --- Settings (standalone; accessible from Profile via pushNamed) ---
  GoRoute(
    name: RouteNames.settings,
    path: '/${RouteNames.settings}',
    builder: (context, state) => const SettingsPage(),
  ),
];

/// Injectable router factory.
/// Pass [StubAuthStatusProvider] for now; swap in real implementation
/// when auth is implemented.
final class AppRouter {
  AppRouter._();

  static GoRouter create({
    required AuthStatusProvider authStatusProvider,
    String initialLocation = '/${RouteNames.login}',
    List<NavigatorObserver>? observers,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: _StreamListenable(authStatusProvider.status),
      redirect: (context, state) =>
          authRedirect(state.topRoute?.name, authStatusProvider),
      routes: appRoutes,
      errorBuilder: (context, state) {
        return AppErrorPage(state: state);
      },
      observers: observers ?? [],
      debugLogDiagnostics: false,
    );
  }
}
