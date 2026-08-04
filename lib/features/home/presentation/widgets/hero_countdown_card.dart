// home - Hero Countdown Card widget
//
// Displays the next class with a countdown timer.
// Matches the HTML template's hero countdown section.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';

/// Formats a [Duration] as HH:MM:SS.
String formatCountdown(Duration duration) {
  if (duration.isNegative) duration = Duration.zero;
  final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// A pulsing dot indicator matching the HTML `animate-ping` effect.
/// Uses [AnimationController] with `.repeat()` for an infinite pulse cycle.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              final scale = 0.6 + (value * 0.8);
              final opacity = (0.8 - value * 0.6).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 10,
            height: 10,
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

/// Hero countdown card with a live-updating countdown timer.
/// The timer ticks every second via [Timer.periodic], so the displayed
/// time decrements in real-time without requiring a page refresh.
class HeroCountdownCard extends StatefulWidget {
  const HeroCountdownCard({super.key, required this.nextClass, this.onCtaTap});

  final NextClassEntity nextClass;
  final VoidCallback? onCtaTap;

  @override
  State<HeroCountdownCard> createState() => _HeroCountdownCardState();
}

class _HeroCountdownCardState extends State<HeroCountdownCard> {
  late Timer _timer;
  late Duration _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = widget.nextClass.timeRemaining(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown = widget.nextClass.timeRemaining(DateTime.now());
      });
    });
  }

  @override
  void didUpdateWidget(HeroCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextClass != widget.nextClass) {
      _countdown = widget.nextClass.timeRemaining(DateTime.now());
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onPrimaryContainer = cs.onPrimaryContainer;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: live indicator + SKS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live indicator
                Row(
                  children: [
                    _PulsingDot(color: onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Kelas berikutnya dalam',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                // SKS badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: onPrimaryContainer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.nextClass.sks,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Countdown time
            Text(
              formatCountdown(_countdown),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: onPrimaryContainer,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            // Course name
            Text(
              widget.nextClass.courseName,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            // Divider
            Container(
              height: 1,
              color: onPrimaryContainer.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            // Lecturer + Location row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lecturer
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: onPrimaryContainer.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nextClass.lecturer ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: onPrimaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Dosen Pengampu',
                              style: TextStyle(
                                fontSize: 11,
                                color: onPrimaryContainer.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Location
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.nextClass.location ?? '-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // CTA button — Tonal Button per DESIGN.md
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onCtaTap,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.onPrimaryContainer,
                  foregroundColor: cs.primaryContainer,
                  disabledBackgroundColor: cs.onPrimaryContainer,
                  disabledForegroundColor: cs.primaryContainer,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Lihat Materi Kelas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: cs.primaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
