// home - Hero Countdown Card widget
//
// Displays the next class with a countdown timer.
// Matches the HTML template's hero countdown section.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/shared/widgets/pulsing_dot.dart';

/// Formats a [Duration] as HH:MM:SS.
String formatCountdown(Duration duration) {
  if (duration.isNegative) duration = Duration.zero;
  final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// Hero countdown card with a live-updating countdown timer.
/// The timer ticks every second via [Timer.periodic], so the displayed
/// time decrements in real-time without requiring a page refresh.
class HeroCountdownCard extends StatefulWidget {
  const HeroCountdownCard({super.key, this.nextClass, this.onCtaTap});

  final NextClassEntity? nextClass;
  final VoidCallback? onCtaTap;

  @override
  State<HeroCountdownCard> createState() => _HeroCountdownCardState();
}

class _HeroCountdownCardState extends State<HeroCountdownCard> {
  Timer? _timer;
  Duration _countdown = Duration.zero;

  bool get _hasActiveClass =>
      widget.nextClass != null && widget.nextClass!.courseName.isNotEmpty;

  void _startTimer() {
    _countdown = widget.nextClass!.timeRemaining(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown = widget.nextClass!.timeRemaining(DateTime.now());
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void initState() {
    super.initState();
    if (_hasActiveClass) _startTimer();
  }

  @override
  void didUpdateWidget(HeroCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive =
        oldWidget.nextClass != null &&
        oldWidget.nextClass!.courseName.isNotEmpty;
    if (_hasActiveClass != wasActive) {
      if (_hasActiveClass) {
        _startTimer();
      } else {
        _stopTimer();
      }
    } else if (_hasActiveClass && oldWidget.nextClass != widget.nextClass) {
      _stopTimer();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveClass) return _buildEmptyState(context);

    final cs = Theme.of(context).colorScheme;
    final onPrimaryContainer = cs.onPrimaryContainer;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimens.cardHeroRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
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
                    PulsingDot(
                      color: onPrimaryContainer,
                      size: AppDimens.dotMD,
                      duration: AppDurations.countdown,
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Text(
                      AppStrings.homeNextClassIn,
                      style: TextStyle(
                        fontSize: AppDimens.textBase,
                        fontWeight: FontWeight.w600,
                        color: onPrimaryContainer.withValues(
                          alpha: ColorValues.opacityVeryHigh,
                        ),
                      ),
                    ),
                  ],
                ),
                // SKS badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space12,
                    vertical: AppDimens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: onPrimaryContainer.withValues(
                      alpha: ColorValues.opacityLow,
                    ),
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    widget.nextClass!.sks,
                    style: TextStyle(
                      fontSize: AppDimens.textSM,
                      fontWeight: FontWeight.bold,
                      color: onPrimaryContainer.withValues(
                        alpha: ColorValues.opacityFull,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space20),
            // Countdown time
            Text(
              formatCountdown(_countdown),
              style: TextStyle(
                fontSize: AppDimens.textHero,
                fontWeight: FontWeight.w800,
                color: onPrimaryContainer,
                letterSpacing: AppDimens.letterSpacingTight,
              ),
            ),
            const SizedBox(height: AppDimens.space4),
            // Course name
            Text(
              widget.nextClass!.courseName,
              style: TextStyle(
                fontSize: AppDimens.text3XL,
                fontWeight: FontWeight.bold,
                color: onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppDimens.space20),
            // Divider
            Container(
              height: 1,
              color: onPrimaryContainer.withValues(
                alpha: ColorValues.opacityMedium,
              ),
            ),
            const SizedBox(height: AppDimens.space20),
            // Lecturer + Location row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lecturer
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: AppDimens.iconXL,
                        height: AppDimens.iconXL,
                        decoration: BoxDecoration(
                          color: onPrimaryContainer.withValues(
                            alpha: ColorValues.opacityLow,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: AppDimens.iconSM,
                          color: onPrimaryContainer.withValues(
                            alpha: ColorValues.opacityMax,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.space10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nextClass!.lecturer ?? '-',
                              style: TextStyle(
                                fontSize: AppDimens.textBase,
                                fontWeight: FontWeight.bold,
                                color: onPrimaryContainer.withValues(
                                  alpha: ColorValues.opacityNearFull,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              AppStrings.homeLecturerLabel,
                              style: TextStyle(
                                fontSize: AppDimens.textXS,
                                color: onPrimaryContainer.withValues(
                                  alpha: ColorValues.opacityHigh,
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
                        size: AppDimens.iconSM,
                        color: onPrimaryContainer.withValues(
                          alpha: ColorValues.opacityVeryHigh,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space6),
                      Flexible(
                        child: Text(
                          widget.nextClass!.location ?? '-',
                          style: TextStyle(
                            fontSize: AppDimens.textBase,
                            fontWeight: FontWeight.w500,
                            color: onPrimaryContainer.withValues(
                              alpha: ColorValues.opacityMax,
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
            const SizedBox(height: AppDimens.space20),
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
                    borderRadius: BorderRadius.circular(AppDimens.radius3XL),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimens.space14,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.homeViewMaterials,
                      style: TextStyle(
                        fontSize: AppDimens.textMD,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Icon(
                      Icons.arrow_forward,
                      size: AppDimens.iconSM,
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

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimens.cardHeroRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: AppDimens.iconLG,
              color: onSurface.withValues(alpha: ColorValues.opacityHigh),
            ),
            const SizedBox(height: AppDimens.space16),
            Text(
              AppStrings.homeEmptyClassTitle,
              style: TextStyle(
                fontSize: AppDimens.text2XL,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: AppDimens.space4),
            Text(
              AppStrings.homeEmptyClassSubtitle,
              style: TextStyle(
                fontSize: AppDimens.textBase,
                color: onSurface.withValues(alpha: ColorValues.opacityVeryHigh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
