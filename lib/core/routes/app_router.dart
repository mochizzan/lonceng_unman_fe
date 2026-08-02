// Route configuration using go_router
// Defines all app routes based on DESIGN.md navigation structure
//
// Routes:
// - /login → LoginPage (auth flow)
// - /main → Bottom navigation shell (Home, Jadwal, Profile)
// - /data-initialization → DataInitializationPage (post-login setup)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Route path constants (Task 1: centralized route names)
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

// Import feature pages
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/home/presentation/pages/home_page.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/profile_page.dart';

final GoRouter router = GoRouter(
  initialLocation: RouteNames.login,
  routes: <RouteBase>[
    GoRoute(
      path: RouteNames.login,
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    // ShellRoute for bottom navigation
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return _MainShellScaffold(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: RouteNames.home,
          builder: (BuildContext context, GoRouterState state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: RouteNames.jadwal,
          builder: (BuildContext context, GoRouterState state) {
            return const JadwalPage();
          },
        ),
        GoRoute(
          path: RouteNames.profile,
          builder: (BuildContext context, GoRouterState state) {
            return const ProfilePage();
          },
        ),
      ],
    ),
  ],
);

// Floating Bottom Navigation Bar Shell (from DESIGN.md section 4)
class _MainShellScaffold extends StatefulWidget {
  const _MainShellScaffold({required this.child});

  final Widget child;

  @override
  State<_MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends State<_MainShellScaffold> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GoRouterState state = GoRouterState.of(context);
    final String location = state.matchedLocation;
    setState(() {
      _currentIndex = _locationToIndex(location);
    });
  }

  int _locationToIndex(String location) {
    if (location.startsWith(RouteNames.home)) return 0;
    if (location.startsWith(RouteNames.jadwal)) return 1;
    if (location.startsWith(RouteNames.profile)) return 2;
    return 0;
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate using go_router
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.jadwal);
        break;
      case 2:
        context.go(RouteNames.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// Floating Bottom Navigation Bar (DESIGN.md section 3.6 & 4)
// Fixed surface color #201B11 across both light and dark themes
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        // Fixed Navbar Surface color from DESIGN.md
        // Use fixed color regardless of theme (light/dark agnostic)
        color: const Color(0xFF201B11),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000), // rgba(0,0,0,0.25)
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: const Color(0xFF201B11), // Fixed navbar color
        selectedItemColor:
            const Color(0xFFFFFFFF), // On Navbar Surface fixed color
        unselectedItemColor: const Color(0xFFFBEFDE), // On Navbar Surface
        selectedLabelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
