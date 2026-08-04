// lib/core/routes/main_shell_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';

/// Stateless shell scaffold for the bottom-navigation group.
/// The [currentIndex] is derived externally from router state,
/// fixing the deep-link index desync bug in the original StatefulWidget.
class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(RouteNames.home);
      case 1:
        context.goNamed(RouteNames.jadwal);
      case 2:
        context.goNamed(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: child,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}

/// Floating Bottom Navigation Bar (DESIGN.md section 3.6 & 4)
/// Fixed surface color #201B11 (#1C1B1A in HTML template) across both
/// light and dark themes. Active icon sits inside a yellow primary-container
/// pill, matching the HTML template design.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  Widget _buildItem(BuildContext context, IconData icon, int index) {
    final isActive = currentIndex == index;

    return SizedBox(
      width: 64,
      height: 56,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isActive ? 52 : 44,
            height: isActive ? 52 : 44,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).extension<AppColors>()!.navbarActivePill
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? Theme.of(context).extension<AppColors>()!.onNavbarActivePill
                  : Theme.of(context).extension<AppColors>()!.onNavbarSurface,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppColors>()!.navbarSurface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildItem(context, Icons.home_rounded, 0),
          _buildItem(context, Icons.calendar_month_rounded, 1),
          _buildItem(context, Icons.person_rounded, 2),
        ],
      ),
    );
  }
}
