import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/widgets/jadwal_card.dart';

class JadwalTimeline extends StatelessWidget {
  const JadwalTimeline({super.key, required this.items});

  final List<JadwalScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
      child: Column(
        children: List.generate(items.length, (index) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot column
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _buildDot(cs, items[index]),
                      if (index < items.length - 1)
                        Expanded(
                          child: Container(width: 2, color: cs.outlineVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.space16),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.space16),
                    child: JadwalCard(item: items[index], index: index),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDot(ColorScheme cs, JadwalScheduleItem item) {
    final isOngoing = item.status == JadwalScheduleStatus.ongoing;

    if (isOngoing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: _PulsingDot(color: cs.primary),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant, width: 4),
      ),
      child: Center(
        child: Container(
          width: AppDimens.dotSM,
          height: AppDimens.dotSM,
          decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

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
      duration: AppDurations.verySlow,
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
      width: 24,
      height: 24,
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
                  width: 24,
                  height: 24,
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
            width: AppDimens.dotMD,
            height: AppDimens.dotMD,
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
