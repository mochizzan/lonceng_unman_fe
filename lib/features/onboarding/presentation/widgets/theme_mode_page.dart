import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

/// Slide 4: Theme Mode — light/dark/system selection with mandatory choice.
class ThemeModePage extends StatefulWidget {
  const ThemeModePage({
    super.key,
    required this.themeNotifier,
    required this.onCompleted,
  });

  final ThemeNotifier themeNotifier;
  final VoidCallback onCompleted;

  @override
  State<ThemeModePage> createState() => _ThemeModePageState();
}

class _ThemeModePageState extends State<ThemeModePage> {
  late AppThemeMode _selectedMode;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.themeNotifier.currentMode;
  }

  Future<void> _selectMode(AppThemeMode mode) async {
    setState(() => _selectedMode = mode);
    await widget.themeNotifier.setMode(mode);
  }

  Future<void> _handleComplete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    try {
      await widget.themeNotifier.setMode(_selectedMode);
      widget.onCompleted();
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

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
          const Spacer(flex: 2),
          // Title
          Text(
            AppStrings.onboardingThemeTitle,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space8)),
          // Description
          Text(
            AppStrings.onboardingThemeDescription,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: sp(context, AppDimens.space32)),
          // Theme buttons
          _ThemeButton(
            icon: Icons.light_mode_outlined,
            label: AppStrings.settingsThemeLight,
            isSelected: _selectedMode == AppThemeMode.light,
            onTap: () => _selectMode(AppThemeMode.light),
          ),
          SizedBox(height: sp(context, AppDimens.space12)),
          _ThemeButton(
            icon: Icons.dark_mode_outlined,
            label: AppStrings.settingsThemeDark,
            isSelected: _selectedMode == AppThemeMode.dark,
            onTap: () => _selectMode(AppThemeMode.dark),
          ),
          SizedBox(height: sp(context, AppDimens.space12)),
          _ThemeButton(
            icon: Icons.phone_android_outlined,
            label: AppStrings.settingsThemeSystem,
            isSelected: _selectedMode == AppThemeMode.system,
            onTap: () => _selectMode(AppThemeMode.system),
          ),
          const Spacer(flex: 2),
          // Get Started button
          FilledButton(
            onPressed: _isCompleting ? null : _handleComplete,
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
            child: _isCompleting
                ? SizedBox(
                    width: sp(context, AppDimens.iconMD),
                    height: sp(context, AppDimens.iconMD),
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimens.borderWidthMedium,
                      color: cs.onPrimaryContainer,
                    ),
                  )
                : Text(
                    AppStrings.onboardingGetStarted,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          SizedBox(height: sp(context, AppDimens.space24)),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: sp(context, AppDimens.space20),
          vertical: sp(context, AppDimens.space16),
        ),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected
                ? AppDimens.borderWidthMedium
                : AppDimens.borderWidthThin,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: sp(context, AppDimens.iconLG),
              color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            SizedBox(width: sp(context, AppDimens.space12)),
            Expanded(
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: sp(context, AppDimens.iconMD),
                color: cs.onPrimaryContainer,
              ),
          ],
        ),
      ),
    );
  }
}
