// Shared PulsingDot widget — eliminates 3 private _PulsingDot duplicates.
//
// Animated pulsing circle indicator used in hero countdown card,
// today schedule timeline, and jadwal timeline.
// Uses [AnimationController] with `.repeat()` for an infinite pulse cycle.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

/// A pulsing dot indicator matching the HTML `animate-ping` effect.
///
/// The outer pulse ring is 2x the inner dot [size]. The inner dot is solid
/// while the outer ring scales and fades in a repeating animation.
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    required this.color,
    this.size = AppDimens.dotMD,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Color color;
  final double size;
  final Duration duration;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double containerSize = widget.size * 2;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              final scale = 0.6 + (value * 0.8);
              final opacity = (0.8 - value * 0.6).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          // Inner dot
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
