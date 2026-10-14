import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/user_data_sync_service.dart';
import '../../../shared/widgets/brand.dart';

/// 3-page onboarding flow
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.auto_stories_outlined,
      titleKey: 'onboarding.page1_title',
      subtitleKey: 'onboarding.page1_subtitle',
      color: AppColors.rose,
    ),
    _OnboardingPage(
      icon: Icons.casino_outlined,
      titleKey: 'onboarding.page2_title',
      subtitleKey: 'onboarding.page2_subtitle',
      color: AppColors.champagne,
    ),
    _OnboardingPage(
      icon: Icons.lock_outline,
      titleKey: 'onboarding.page3_title',
      subtitleKey: 'onboarding.page3_subtitle',
      color: AppColors.jewelDusk,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.normal,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await PreferencesService.instance.setOnboardingCompleted(true);
    UserDataSyncService.instance
        .syncSettingsPatch({'onboarding_completed': true});
    if (mounted) {
      context.go(AppRoutes.catalog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VelvetBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextButton(
                    onPressed: _onSkip,
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.mist),
                    child: Text('common.skip'.tr()),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _buildPage(context, page, index == _currentPage);
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: AppAnimations.normal,
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 28 : 12,
                      height: 2,
                      color: isActive ? AppColors.champagne : AppColors.outline,
                    );
                  }),
                ),
              ),

              // Action button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    child: Text(
                      _currentPage < _pages.length - 1
                          ? 'common.next'.tr()
                          : 'onboarding.get_started'.tr(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPage page, bool isActive) {
    final index = _pages.indexOf(page) + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon framed by two concentric hairline rings
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.hairline),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: page.color.withOpacity(0.06),
                    border: Border.all(color: page.color.withOpacity(0.45)),
                  ),
                  child: Icon(page.icon, size: 44, color: page.color),
                ),
              ],
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
              .fadeIn(),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            '${index.toString().padLeft(2, '0')}  —  ${_pages.length.toString().padLeft(2, '0')}',
            style: AppTypography.eyebrow.copyWith(color: AppColors.champagne),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            page.titleKey.tr(),
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 100.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.md),

          // Subtitle
          Text(
            page.subtitleKey.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mist,
                ),
            textAlign: TextAlign.center,
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.color,
  });
}
