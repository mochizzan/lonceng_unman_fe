// lib/core/routes/main_shell_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

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

  static const _navbarBg = Color(0xFF201B11);
  static const _activeBg = Color(0xFFFFC107); // primary container
  static const _inactiveColor = Color(0xFFFBEFDE);
  static const _activeIconColor = Color(0xFF402D00); // on-primary-container

  Widget _buildItem(IconData icon, int index) {
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
              color: isActive ? _activeBg : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? _activeIconColor : _inactiveColor,
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _navbarBg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildItem(Icons.home_rounded, 0),
          _buildItem(Icons.calendar_month_rounded, 1),
          _buildItem(Icons.person_rounded, 2),
        ],
      ),
    );
  }
}
