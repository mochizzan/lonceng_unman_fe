// lib/core/routes/app_router.dart
//
// Route configuration using go_router.
// Defines all app routes based on DESIGN.md navigation structure.
//
// Post-login flow: authenticated users go straight to /home.
// Data initialization runs at login time; home shows skeletons while
// cache data loads.

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';

import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_bloc.dart';
import 'package:lonceng_unman_fe/features/home/presentation/pages/home_page.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_bloc.dart';
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
import 'package:lonceng_unman_fe/features/khs/presentation/pages/khs_detail_page.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_cubit.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/avatar_crop_page.dart';
import 'package:lonceng_unman_fe/features/student_profile/presentation/pages/profil_lengkap_page.dart';

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
  final isOnboarding = matchedRoute == RouteNames.onboarding;

  // Unauthenticated: block everything except /login and /onboarding.
  if (status == AuthStatus.unauthenticated) {
    return (isLogin || isOnboarding) ? null : '/${RouteNames.login}';
  }

  // Authenticated: redirect away from login to home.
  if (isLogin) return '/${RouteNames.home}';

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

int? _indexForRoute(String? routeName) {
  switch (routeName) {
    case RouteNames.home:
      return 0;
    case RouteNames.jadwal:
      return 1;
    case RouteNames.profile:
      return 2;
    default:
      return null;
  }
}

/// Redirect logic for the avatar crop route. Returns the profile path if
/// [extra] is not bytes (route should only be reached with valid image bytes),
/// or null to allow navigation. Pure function for testability.
String? avatarCropRedirect(Object? extra) =>
    extra is Uint8List ? null : '/${RouteNames.profile}';

List<RouteBase> _buildRoutes(
  AuthStatusNotifier authStatusNotifier,
  ThemeNotifier themeNotifier,
) {
  return <RouteBase>[
    // --- Auth (standalone, no bottom nav) ---
    GoRoute(
      name: RouteNames.login,
      path: '/${RouteNames.login}',
      builder: (context, state) => BlocProvider(
        create: (_) => AuthBloc(Services.get<GetAuth>()),
        child: LoginPage(authStatusNotifier: authStatusNotifier),
      ),
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
            BlocProvider(create: (_) => HomeBloc(Services.get<GetHome>())),
            BlocProvider(create: (_) => JadwalBloc(Services.get<GetJadwal>())),
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
            create: (_) => ProfileBloc(
              Services.get<GetProfile>(),
              Services.get<BioCacheService>(),
            )..add(const ProfileFetchRequested()),
            child: const ProfilePage(),
          ),
        ),
        // Settings is inside ShellRoute so it inherits NotificationCubit
        GoRoute(
          name: RouteNames.settings,
          path: '/${RouteNames.settings}',
          builder: (context, state) => SettingsPage(notifier: themeNotifier),
        ),
      ],
    ),
    // --- Avatar Crop (standalone; reached only via go_router pushNamed) ---
    GoRoute(
      name: RouteNames.avatarCrop,
      path: '/${RouteNames.profile}/crop',
      redirect: (context, state) => avatarCropRedirect(state.extra),
      builder: (context, state) =>
          AvatarCropPage(imageBytes: state.extra! as Uint8List),
    ),

    // --- Onboarding (first-time users) ---
    GoRoute(
      name: RouteNames.onboarding,
      path: '/${RouteNames.onboarding}',
      builder: (context, state) => OnboardingPage(
        themeNotifier: themeNotifier,
        onboardingRepository: Services.get<OnboardingRepository>(),
      ),
    ),

    // --- KHS Detail (standalone; accessible from Home IPK section) ---
    GoRoute(
      name: RouteNames.khs,
      path: '/${RouteNames.khs}',
      builder: (context, state) {
        final tahunAjaran = state.uri.queryParameters['tahunAjaran'] ?? '';
        final semester = state.uri.queryParameters['semester'] ?? '';
        return BlocProvider(
          create: (_) => KhsDetailCubit(tahunAjaran: tahunAjaran)..loadAll(),
          child: KhsDetailPage(tahunAjaran: tahunAjaran, semester: semester),
        );
      },
    ),

    // --- Profil Lengkap (standalone; accessible from Profile page) ---
    GoRoute(
      name: RouteNames.profilLengkap,
      path: '/${RouteNames.profilLengkap}',
      builder: (context, state) => const ProfilLengkapPage(),
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
            state.matchedLocation != '/${RouteNames.onboarding}') {
          return '/${RouteNames.onboarding}';
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
