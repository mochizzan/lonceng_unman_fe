import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

/// Slide 1: Welcome — app logo, name, and tagline.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPaddingHorizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 3),
          const Center(child: BellLogo()),
          SizedBox(height: sp(context, AppDimens.space24)),
          Text(
            AppStrings.appName,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space8)),
          Text(
            AppStrings.onboardingWelcomeTagline,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}
