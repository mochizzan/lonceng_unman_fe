// lib/core/widgets/scroll_hide_controller.dart
//
// Reusable scroll-hide controller for bottom navigation bars.
//
// Detects user-initiated scroll direction via ScrollNotification and drives
// an AnimationController that transitions between visible (0.0) and hidden (1.0).
// Designed for composition with AnimatedBuilder — no widget coupling.
//
// Usage:
//   final _scrollHide = ScrollHideController(vsync: this);
//   // In NotificationListener:
//   onNotification: _scrollHide.handleScroll,
//   // In AnimatedBuilder:
//   animation: _scrollHide.animation,
//   // On tab switch:
//   _scrollHide.show();

import 'package:flutter/material.dart';

/// Configuration for [ScrollHideController] behavior.
class ScrollHideConfig {
  const ScrollHideConfig({
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOut,
    this.ignorePointerThreshold = 0.5,
  });

  /// Duration of the show/hide transition.
  final Duration duration;

  /// Curve applied to the animation.
  final Curve curve;

  /// Fraction of hide-progress at which pointer events pass through.
  /// 0.5 means taps pass through when navbar is half-hidden.
  final double ignorePointerThreshold;

  static const defaults = ScrollHideConfig();
}

/// Scroll-hide animation controller.
///
/// Owns an [AnimationController] whose [value] transitions from 0.0 (visible)
/// to 1.0 (hidden) based on scroll direction. Call [handleScroll] from a
/// [NotificationListener<ScrollNotification>] and feed [animation] to an
/// [AnimatedBuilder].
///
/// Only responds to user-initiated drags ([ScrollUpdateNotification] with
/// non-null [dragDetails]), ignoring programmatic scrolls and overscroll.
class ScrollHideController {
  ScrollHideController({
    required TickerProvider vsync,
    ScrollHideConfig config = ScrollHideConfig.defaults,
  }) : _controller = AnimationController(
         vsync: vsync,
         duration: config.duration,
       ),
       _config = config;

  final AnimationController _controller;
  final ScrollHideConfig _config;
  double _lastPixels = 0;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Driven animation — feed this to AnimatedBuilder.
  /// Values: 0.0 (fully visible) → 1.0 (fully hidden), with [_config.curve].
  Animation<double> get animation =>
      _controller.drive(CurveTween(curve: _config.curve));

  /// Raw controller value (0.0–1.0) before curve is applied.
  double get value => _controller.value;

  /// True when the navbar is past the ignore-pointer threshold.
  bool get isIgnored => _controller.value > _config.ignorePointerThreshold;

  /// Feed scroll notifications here. Returns `false` (never consumes).
  ///
  /// Tracks pixel deltas between consecutive [ScrollUpdateNotification]s.
  /// Calls [AnimationController.forward] on downward scroll and [reverse] on
  /// upward scroll. Because forward/reverse start from the current value,
  /// mid-animation direction changes are seamless.
  bool handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final pixels = notification.metrics.pixels;
      final delta = pixels - _lastPixels;
      _lastPixels = pixels;

      if (delta > 0) {
        // Scrolling down → hide
        _controller.forward();
      } else if (delta < 0) {
        // Scrolling up → show
        _controller.reverse();
      }
    }

    if (notification is ScrollEndNotification) {
      _lastPixels = notification.metrics.pixels;
    }

    return false; // Never consume — let notification propagate
  }

  /// Snap to fully visible (value = 0.0). Call on tab/page switch.
  void show() => _controller.reset();

  /// Update animation duration at runtime.
  set duration(Duration d) => _controller.duration = d;

  void dispose() => _controller.dispose();
}
