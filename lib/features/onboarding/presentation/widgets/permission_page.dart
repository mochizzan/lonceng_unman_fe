import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/core/services/fcm_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Slide 3: Permission — notification permission request with status feedback.
class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _isGranted = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (kIsWeb) {
      setState(() => _isGranted = true);
      return;
    }
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() => _isGranted = status.isGranted);
    }
  }

  Future<void> _requestPermission() async {
    if (_isRequesting || _isGranted) return;
    setState(() => _isRequesting = true);
    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        // Also request FCM-level permission (iOS APNs).
        await FcmService.instance.requestPermission();
      }
      if (mounted) {
        setState(() => _isGranted = status.isGranted);
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
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
          // Icon
          Center(
            child: Container(
              width: sp(context, AppDimens.space80),
              height: sp(context, AppDimens.space80),
              decoration: BoxDecoration(
                color: _isGranted ? cs.primaryContainer : cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isGranted
                    ? Icons.check_circle_outline
                    : Icons.notifications_outlined,
                size: sp(context, AppDimens.iconXL),
                color: _isGranted
                    ? cs.onPrimaryContainer
                    : cs.onSecondaryContainer,
              ),
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space24)),
          // Title
          Text(
            _isGranted
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
            _isGranted
                ? AppStrings.onboardingPermissionGrantedDesc
                : AppStrings.onboardingPermissionDescription,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(flex: 2),
          // Button
          if (!_isGranted)
            FilledButton(
              onPressed: _isRequesting ? null : _requestPermission,
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
              child: _isRequesting
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
      ),
    );
  }
}
