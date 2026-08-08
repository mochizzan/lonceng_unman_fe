import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/cubit/permission_cubit.dart';

/// Slide 3: Permission — notification permission request with status feedback.
class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPaddingHorizontal,
      ),
      child: BlocBuilder<PermissionCubit, PermissionState>(
        builder: (context, state) {
          final isGranted = state.isGranted;
          final isRequesting = state.isRequesting;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Icon
              Center(
                child: Container(
                  width: sp(context, AppDimens.space80),
                  height: sp(context, AppDimens.space80),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? cs.primaryContainer
                        : cs.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGranted
                        ? Icons.check_circle_outline
                        : Icons.notifications_outlined,
                    size: sp(context, AppDimens.iconXL),
                    color: isGranted
                        ? cs.onPrimaryContainer
                        : cs.onSecondaryContainer,
                  ),
                ),
              ),
              SizedBox(height: sp(context, AppDimens.space24)),
              // Title
              Text(
                isGranted
                    ? AppStrings.onboardingPermissionGranted
                    : AppStrings.onboardingPermissionTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: sp(context, AppDimens.space8)),
              // Description
              Text(
                isGranted
                    ? AppStrings.onboardingPermissionGrantedDesc
                    : AppStrings.onboardingPermissionDescription,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              // Button
              if (!isGranted)
                FilledButton(
                  onPressed: isRequesting
                      ? null
                      : () =>
                            context.read<PermissionCubit>().requestPermission(),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    padding: EdgeInsets.symmetric(
                      vertical: sp(context, AppDimens.space16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                  ),
                  child: isRequesting
                      ? SizedBox(
                          width: sp(context, AppDimens.iconMD),
                          height: sp(context, AppDimens.iconMD),
                          child: CircularProgressIndicator(
                            strokeWidth: AppDimens.borderWidthMedium,
                            color: cs.onPrimaryContainer,
                          ),
                        )
                      : Text(
                          AppStrings.onboardingPermissionAllow,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              SizedBox(height: sp(context, AppDimens.space24)),
            ],
          );
        },
      ),
    );
  }
}
