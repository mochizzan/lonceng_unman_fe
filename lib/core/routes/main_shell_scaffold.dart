// lib/core/routes/main_shell_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/core/widgets/barrel.dart';

/// Shell scaffold for the bottom-navigation group.
///
/// The [currentIndex] is derived externally from router state.
/// The navbar auto-hides on scroll-down and reappears on scroll-up via
/// [ScrollHideController]. The controller is reset to visible on tab switch.
class MainShellScaffold extends StatefulWidget {
  const MainShellScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    this.scrollHideConfig,
  });

  final int currentIndex;
  final Widget child;

  /// Optional scroll-hide configuration. Uses [ScrollHideConfig.defaults]
  /// when null.
  final ScrollHideConfig? scrollHideConfig;

  @override
  State<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends State<MainShellScaffold>
    with SingleTickerProviderStateMixin {
  late final ScrollHideController _scrollHide;
  final _navBarKey = GlobalKey();
  double _navBarHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollHide = ScrollHideController(
      vsync: this,
      config: widget.scrollHideConfig ?? ScrollHideConfig.defaults,
    );
    // Measure the rendered navbar height after the first frame so the
    // slide distance matches the actual widget, not a magic number.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureNavBar());
  }

  @override
  void didUpdateWidget(MainShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset navbar to visible when the user switches tabs.
    if (widget.currentIndex != oldWidget.currentIndex) {
      _scrollHide.show();
    }
  }

  @override
  void dispose() {
    _scrollHide.dispose();
    super.dispose();
  }

  /// Read the FloatingNavBar's rendered height (+ margins) and use it as
  /// the slide-off distance. Falls back to 0 on first frame if unmounted.
  void _measureNavBar() {
    final box = _navBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && mounted) {
      // The FloatingNavBar Container has vertical margin 12+20 = 32px
      // outside its RenderBox. Add it so the slide clears the viewport.
      setState(() => _navBarHeight = box.size.height + 32);
    }
  }

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
      body: NotificationListener<ScrollNotification>(
        onNotification: _scrollHide.handleScroll,
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _scrollHide.animation,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(0, _scrollHide.value * _navBarHeight),
            child: Opacity(
              opacity: 1.0 - _scrollHide.value,
              child: IgnorePointer(
                ignoring: _scrollHide.isIgnored,
                child: child,
              ),
            ),
          );
        },
        child: KeyedSubtree(
          key: _navBarKey,
          child: FloatingNavBar(
            currentIndex: widget.currentIndex,
            onTap: (index) => _onTap(context, index),
          ),
        ),
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
      width: AppDimens.navBarHeight,
      height: AppDimens.navBarItemHeight,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        child: Center(
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: Curves.easeOut,
            width: isActive
                ? AppDimens.navBarPillWidth
                : AppDimens.navBarPillHeight,
            height: isActive
                ? AppDimens.navBarPillWidth
                : AppDimens.navBarPillHeight,
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
              size: AppDimens.iconLG,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppDimens.navBarMarginHorizontal,
        right: AppDimens.navBarMarginHorizontal,
        bottom: AppDimens.navBarMarginBottom,
        top: AppDimens.space12,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.navBarPaddingVertical,
        horizontal: AppDimens.navBarPaddingHorizontal,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppColors>()!.navbarSurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25),
            offset: Offset(0, AppDimens.shadowNavBarOffsetY),
            blurRadius: AppDimens.shadowNavBarBlurRadius,
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
