// lib/core/routes/main_shell_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
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
    this.currentIndex,
    required this.child,
    this.scrollHideConfig,
  });

  /// Null hides the bottom nav (e.g. Settings pushed route).
  final int? currentIndex;
  final Widget child;

  /// Optional scroll-hide configuration. Uses [ScrollHideConfig.defaults]
  /// when null.
  final ScrollHideConfig? scrollHideConfig;

  @override
  State<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends State<MainShellScaffold>
    with TickerProviderStateMixin {
  late final ScrollHideController _scrollHide;
  late final AnimationController _modalAnimController;
  final _navBarKey = GlobalKey();
  double _navBarHeight = 0;
  bool _modalVisible = true; // navbar terlihat = true
  bool _isAnimatingModal = false;

  @override
  void initState() {
    super.initState();
    _scrollHide = ScrollHideController(
      vsync: this,
      config: widget.scrollHideConfig ?? ScrollHideConfig.defaults,
    );
    _modalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // 1.0 = navbar terlihat (tidak ter-slide)
    );
    // Listen perubahan visibilitas navbar saat modal (bottom sheet) buka/tutup.
    Services.get<NavbarVisibilityNotifier>().addListener(_onModalVisibility);
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
    Services.get<NavbarVisibilityNotifier>().removeListener(_onModalVisibility);
    _modalAnimController.dispose();
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

  /// Handle perubahan visibilitas navbar dari modal (bottom sheet).
  /// Navbar slide-down saat modal buka, slide-up saat modal tutup.
  void _onModalVisibility() {
    final hidden = Services.get<NavbarVisibilityNotifier>().value;
    if (!mounted) return;

    if (hidden && _modalVisible) {
      // Modal dibuka → slide navbar ke bawah.
      _modalVisible = false;
      _modalAnimController.reverse();
    } else if (!hidden && !_modalVisible) {
      // Modal ditutup → slide navbar ke atas.
      _modalVisible = true;
      _isAnimatingModal = true;
      _scrollHide.show(); // Reset scroll ke visible.
      _modalAnimController.forward().then((_) {
        if (mounted) {
          // Setelah animasi selesai, izinkan scroll-hide berfungsi normal.
          _isAnimatingModal = false;
        }
      });
    }
  }

  /// Wrapper untuk scroll hide — menghormati animasi modal.
  bool _handleScroll(ScrollNotification notification) {
    // Selama animasi modal berlangsung, jangan proses scroll.
    if (_isAnimatingModal) return false;
    return _scrollHide.handleScroll(notification);
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
    // When currentIndex is null (e.g. Settings sub-route), hide the nav bar.
    final showNav = widget.currentIndex != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: widget.child,
      ),
      bottomNavigationBar: showNav
          ? AnimatedBuilder(
              animation: _modalAnimController,
              builder: (_, child) {
                // Slide offset gabungan: scroll-hide + modal-hide.
                final scrollOffset = _scrollHide.value * _navBarHeight;
                final modalOffset =
                    (1.0 - _modalAnimController.value) * _navBarHeight;
                final totalOffset = scrollOffset + modalOffset;

                // Opacity gabungan.
                final scrollOpacity = 1.0 - _scrollHide.value;
                final modalOpacity = _modalAnimController.value;
                final totalOpacity = scrollOpacity < modalOpacity
                    ? scrollOpacity
                    : modalOpacity;

                return Transform.translate(
                  offset: Offset(0, totalOffset),
                  child: Opacity(
                    opacity: totalOpacity,
                    child: IgnorePointer(
                      ignoring:
                          _scrollHide.isIgnored ||
                          _modalAnimController.value < 0.5,
                      child: child,
                    ),
                  ),
                );
              },
              child: KeyedSubtree(
                key: _navBarKey,
                child: FloatingNavBar(
                  currentIndex: widget.currentIndex!,
                  onTap: (index) => _onTap(context, index),
                ),
              ),
            )
          : null,
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
