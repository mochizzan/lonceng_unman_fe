// home - Hero Countdown Card widget
//
// Displays the next class with a countdown timer.
// Matches the HTML template's hero countdown section.

import 'dart:ui';

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
/// Uses a self-animated builder so it does not require an external
/// AnimationController or Timer, keeping it test-friendly.
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
            builder: (context, value, child) {
              return Opacity(
                opacity: 0.4 * value,
                child: Transform.scale(
                  scale: 0.6 + value * 1.0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class HeroCountdownCard extends StatelessWidget {
  const HeroCountdownCard({
    super.key,
    required this.nextClass,
    this.countdown,
    this.onCtaTap,
  });

  final NextClassEntity nextClass;
  final Duration? countdown;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final effectiveCountdown = countdown ?? nextClass.timeRemaining(now);
    final onPrimaryContainer = cs.onPrimaryContainer;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          // Subtle texture circles (from HTML)
          Positioned(
            right: -40,
            top: -64,
            width: 192,
            height: 192,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            left: -56,
            bottom: 0,
            width: 160,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // Content
          Padding(
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
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: _PulsingDot(color: Color(0xFF402D00)),
                        ),
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
                        nextClass.sks,
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
                  formatCountdown(effectiveCountdown),
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
                  nextClass.courseName,
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
                                  nextClass.lecturer ?? '-',
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
                              nextClass.location ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: onPrimaryContainer.withValues(
                                  alpha: 0.8,
                                ),
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
                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onCtaTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: onPrimaryContainer,
                      foregroundColor: cs.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
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
        ],
      ),
    );
  }
}
