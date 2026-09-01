import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/cubit/permission_cubit.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/welcome_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/features_benefits_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/permission_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/theme_mode_page.dart';

/// Main onboarding page — fullscreen carousel with PageView.
///
/// Flow: Welcome → Features → Permission → Theme Mode → Done.
/// After completion, always navigates to the login page.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.themeNotifier,
    required this.onboardingRepository,
  });

  final ThemeNotifier themeNotifier;
  final OnboardingRepository onboardingRepository;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  late final ThemeNotifier _themeNotifier;
  late final OnboardingRepository _onboardingRepository;
  int _currentPage = 0;
  static const _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _themeNotifier = widget.themeNotifier;
    _onboardingRepository = widget.onboardingRepository;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _handleCompleted() async {
    // 1. Mark onboarding as completed
    await _onboardingRepository.markCompleted();

    if (!mounted) return;

    // 2. Always navigate to login page
    // Even if credentials are cached, user must go through login flow
    // for proper auth validation and data-init pipeline
    context.go('/${RouteNames.login}');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: BlocProvider(
                create: (_) => PermissionCubit()..checkPermission(),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    const WelcomePage(),
                    const FeaturesBenefitsPage(),
                    const PermissionPage(),
                    ThemeModePage(
                      themeNotifier: _themeNotifier,
                      onCompleted: _handleCompleted,
                    ),
                  ],
                ),
              ),
            ),
            // Dot indicators
            Padding(
              padding: EdgeInsets.only(bottom: sp(context, AppDimens.space16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _DotIndicator(
                    isActive: index == _currentPage,
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.isActive, this.onTap});

  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
        width: isActive ? AppDimens.dotLG : AppDimens.dotMD,
        height: AppDimens.dotMD,
        decoration: BoxDecoration(
          color: isActive ? cs.primary : cs.outlineVariant,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
      ),
    );
  }
}
