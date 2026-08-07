import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';

/// Placeholder cards for the home dashboard while data-init / fetch runs.
class HomeSkeletonSliver extends StatelessWidget {
  const HomeSkeletonSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: AppDimens.space16),
        const _SkeletonCard(height: 140),
        const SizedBox(height: AppDimens.space28),
        const Row(
          children: [
            Expanded(child: _SkeletonCard(height: 88)),
            SizedBox(width: AppDimens.space12),
            Expanded(child: _SkeletonCard(height: 88)),
          ],
        ),
        const SizedBox(height: AppDimens.space28),
        const _SkeletonCard(height: 24, widthFactor: 0.4),
        const SizedBox(height: AppDimens.space12),
        const _SkeletonCard(height: 72),
        const SizedBox(height: AppDimens.space12),
        const _SkeletonCard(height: 72),
        const SizedBox(height: AppDimens.space12),
        const _SkeletonCard(height: 72),
      ]),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height, this.widthFactor = 1});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        ),
      ),
    );
  }
}
