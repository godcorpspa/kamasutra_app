import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/router.dart';
import '../../data/providers/providers.dart';

/// Main scaffold with bottom navigation
class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final List<String> _routes = [
    AppRoutes.catalog,
    AppRoutes.shuffle,
    AppRoutes.games,
    AppRoutes.progress,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context) {
    // Update current index based on location
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex = _routes.indexWhere((r) => location.startsWith(r));
    if (_currentIndex < 0) _currentIndex = 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // Floating bar: inset from the screen edges, hairline border, no shadow.
    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.inkRaised,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.auto_stories_outlined,
                activeIcon: Icons.auto_stories,
                label: 'nav.catalog'.tr(),
                isSelected: _currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _NavItem(
                icon: Icons.style_outlined,
                activeIcon: Icons.style,
                label: 'nav.shuffle'.tr(),
                isSelected: _currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _NavItem(
                icon: Icons.casino_outlined,
                activeIcon: Icons.casino,
                label: 'nav.games'.tr(),
                isSelected: _currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              _NavItem(
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights,
                label: 'nav.progress'.tr(),
                isSelected: _currentIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
              _NavItem(
                icon: Icons.more_horiz,
                activeIcon: Icons.more_horiz,
                label: 'nav.settings'.tr(),
                isSelected: _currentIndex == 4,
                onTap: () => _onItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    // Close any open bottom sheet or dialog on the shell navigator
    final shellNav = shellNavigatorKey.currentState;
    if (shellNav != null && shellNav.canPop()) {
      shellNav.pop();
    }
    // Reset catalog favorites filter when leaving the catalog tab
    if (_currentIndex == 0 && index != 0) {
      ref.read(positionFilterProvider.notifier).setFavoritesOnly(false);
    }
    context.go(_routes[index]);
  }
}

/// Custom navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.champagne : AppColors.smoke;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 10.5,
                  letterSpacing: 0.3,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.ivory : AppColors.smoke,
                ),
              ),
              const SizedBox(height: 4),
              // Active indicator: a small champagne dot.
              AnimatedContainer(
                duration: AppDurations.normal,
                curve: Curves.easeOutCubic,
                width: isSelected ? 4 : 0,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.champagne,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Safe word floating button
class SafeWordButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SafeWordButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'safe_word',
      backgroundColor: AppColors.inkHighest,
      onPressed: onPressed,
      tooltip: 'consent.safe_word'.tr(),
      child: const Icon(
        Icons.pause_circle_outline,
        color: AppColors.champagne,
      ),
    );
  }
}

/// Consent check-in dialog
class ConsentCheckInDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onPause;

  const ConsentCheckInDialog({
    super.key,
    required this.onContinue,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        'consent.check_in'.tr(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton.icon(
          onPressed: onContinue,
          icon: const Text('👍'),
          label: Text('consent.all_good'.tr()),
        ),
        TextButton.icon(
          onPressed: onPause,
          icon: const Text('🛑'),
          label: Text('consent.lets_pause'.tr()),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
        ),
      ],
    );
  }
}

/// Paused overlay
class PausedOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onEndSession;

  const PausedOverlay({
    super.key,
    required this.onResume,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink.withOpacity(0.94),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                size: 72,
                color: AppColors.champagne,
              ),
              const SizedBox(height: 24),
              Text(
                'consent.paused_title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.cream,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'consent.paused_message'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mist,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: Text('consent.resume'.tr()),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onEndSession,
                child: Text(
                  'consent.end_session'.tr(),
                  style: const TextStyle(color: AppColors.smoke),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
