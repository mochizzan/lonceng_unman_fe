// home - Hero Countdown Card widget
//
// Displays the next class with a countdown timer.
// Supports two modes:
//   - Upcoming class: countdown DOWN to startTime (HH:MM:SS)
//   - Ongoing class:  count UP from startTime   (HH:MM:SS)
// Shows an empty placeholder when nextClass is null.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/shared/widgets/pulsing_dot.dart';

/// Formats a [Duration] as HH:MM:SS (pure hours, no day rollover).
///
/// Uses [Duration.inHours] which returns total elapsed hours, so a 3-day
/// duration formats as `72:00:00` rather than `00:00:00`.
String formatCountdown(Duration duration) {
  if (duration.isNegative) duration = Duration.zero;
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// Hero countdown card with a live-updating countdown timer.
///
/// When [nextClass] is non-null, shows either:
///   - **Upcoming mode** – timer counts down to the class start time, label
///     reads "SELANJUTNYA".
///   - **Ongoing mode** – timer counts up from the class start time, label
///     reads "SEDANG BERLANGSUNG" with a green pulsing indicator.
///
/// When [nextClass] is null, renders an empty-state placeholder.
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

  // ── Mode detection ──────────────────────────────────────────────

  /// Whether [nextClass] is currently in progress (startTime ≤ now < endTime).
  bool get _isOngoing {
    if (widget.nextClass == null) return false;
    final now = DateTime.now();
    return now.isAfter(widget.nextClass!.startTime) &&
        now.isBefore(widget.nextClass!.endTime);
  }

  // ── Timer lifecycle ─────────────────────────────────────────────

  void _startTimer() {
    _computeCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_computeCountdown);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Recalculates [_countdown] based on current mode.
  void _computeCountdown() {
    final now = DateTime.now();
    if (widget.nextClass == null) {
      _countdown = Duration.zero;
      return;
    }

    final next = widget.nextClass!;
    final ongoing = now.isAfter(next.startTime) && now.isBefore(next.endTime);

    if (ongoing) {
      _countdown = now.difference(next.startTime);
    } else {
      _countdown = next.startTime.difference(now);
      if (_countdown.isNegative) _countdown = Duration.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.nextClass != null) _startTimer();
  }

  @override
  void didUpdateWidget(HeroCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextClass != widget.nextClass) {
      _stopTimer();
      if (widget.nextClass != null) _startTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.nextClass == null) return _buildEmptyState(context);

    final cs = Theme.of(context).colorScheme;
    final onPrimaryContainer = cs.onPrimaryContainer;
    final next = widget.nextClass!;
    final ongoing = _isOngoing;
    final liveColor = ongoing ? Colors.green : onPrimaryContainer;
    final timeRange =
        '${_formatTime(next.startTime)} - ${_formatTime(next.endTime)}';
    final statusLabel = ongoing
        ? AppStrings.jadwalStatusOngoing
        : 'SELANJUTNYA';
    final countdownText = formatCountdown(_countdown);

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
            // ── Top row: live indicator + SKS ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    PulsingDot(
                      color: liveColor,
                      size: AppDimens.dotMD,
                      duration: AppDurations.countdown,
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Text(
                      ongoing
                          ? AppStrings.jadwalStatusOngoing
                          : AppStrings.homeNextClassIn,
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
                    next.sks,
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

            // ── Countdown / elapsed time ───────────────────────
            Text(
              countdownText,
              style: TextStyle(
                fontSize: AppDimens.textHero,
                fontWeight: FontWeight.w800,
                color: onPrimaryContainer,
                letterSpacing: AppDimens.letterSpacingTight,
              ),
            ),
            const SizedBox(height: AppDimens.space4),

            // ── Course name ────────────────────────────────────
            Text(
              next.courseName,
              style: TextStyle(
                fontSize: AppDimens.text3XL,
                fontWeight: FontWeight.bold,
                color: onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppDimens.space4),

            // ── Time range ─────────────────────────────────────
            Text(
              timeRange,
              style: TextStyle(
                fontSize: AppDimens.textBase,
                fontWeight: FontWeight.w500,
                color: onPrimaryContainer.withValues(
                  alpha: ColorValues.opacityMax,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // ── Divider ────────────────────────────────────────
            Container(
              height: 1,
              color: onPrimaryContainer.withValues(
                alpha: ColorValues.opacityMedium,
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // ── Lecturer + Location row ────────────────────────
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
                              next.lecturer ?? '-',
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
                          next.location ?? '-',
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

            // ── Status label ───────────────────────────────────
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: ongoing ? Colors.green : onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // ── CTA button ─────────────────────────────────────
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

  // ── Empty state ───────────────────────────────────────────────

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

  // ── Helpers ───────────────────────────────────────────────────

  /// Formats a [DateTime] as HH:MM (24-hour).
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
