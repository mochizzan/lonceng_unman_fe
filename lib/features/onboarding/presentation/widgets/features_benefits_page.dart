import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

/// Slide 2: Features + Benefits — vertical list of app capabilities.
class FeaturesBenefitsPage extends StatelessWidget {
  const FeaturesBenefitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPaddingHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: sp(context, AppDimens.space48)),
          Text(
            AppStrings.onboardingFeaturesTitle,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space24)),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                vertical: sp(context, AppDimens.space8),
              ),
              itemCount: _features.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: sp(context, AppDimens.space16)),
              itemBuilder: (context, index) {
                final feature = _features[index];
                return _FeatureItem(
                  icon: feature.icon,
                  title: feature.title,
                  description: feature.description,
                );
              },
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space16)),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(sp(context, AppDimens.space20)),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: sp(context, AppDimens.iconXL),
            height: sp(context, AppDimens.iconXL),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimens.radiusMD),
            ),
            child: Icon(
              icon,
              size: sp(context, AppDimens.iconMD),
              color: cs.onPrimaryContainer,
            ),
          ),
          SizedBox(width: sp(context, AppDimens.space12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: sp(context, AppDimens.space2)),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
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

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _features = [
  _FeatureData(
    icon: Icons.timer_outlined,
    title: AppStrings.onboardingFeatureCountdown,
    description: AppStrings.onboardingFeatureCountdownDesc,
  ),
  _FeatureData(
    icon: Icons.notifications_outlined,
    title: AppStrings.onboardingFeatureNotification,
    description: AppStrings.onboardingFeatureNotificationDesc,
  ),
  _FeatureData(
    icon: Icons.calendar_today_outlined,
    title: AppStrings.onboardingFeatureSchedule,
    description: AppStrings.onboardingFeatureScheduleDesc,
  ),
  _FeatureData(
    icon: Icons.person_outline,
    title: AppStrings.onboardingFeatureProfile,
    description: AppStrings.onboardingFeatureProfileDesc,
  ),
];
