import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/welcome_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/features_benefits_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/permission_page.dart';
import 'package:lonceng_unman_fe/features/onboarding/presentation/widgets/theme_mode_page.dart';

/// Main onboarding page — fullscreen carousel with PageView.
///
/// Flow: Welcome → Features → Permission → Theme Mode → Done.
/// After completion, always navigates to the login page.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

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
    _themeNotifier = Services.get<ThemeNotifier>();
    _onboardingRepository = Services.get<OnboardingRepository>();
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
            // Dot indicators
            Padding(
              padding: EdgeInsets.only(bottom: sp(context, AppDimens.space16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _DotIndicator(isActive: index == _currentPage),
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
  const _DotIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
      width: isActive ? AppDimens.dotLG : AppDimens.dotMD,
      height: AppDimens.dotMD,
      decoration: BoxDecoration(
        color: isActive ? cs.primary : cs.outlineVariant,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
    );
  }
}
