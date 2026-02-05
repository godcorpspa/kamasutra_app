import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../app/theme.dart';
import '../../app/router.dart';
import '../../data/services/preferences_service.dart';

/// Main scaffold with bottom navigation
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  DateTime? _lastDoubleTap;

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

    return GestureDetector(
      // Panic exit: double-tap anywhere
      onDoubleTap: _handlePanicExit,
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  void _handlePanicExit() {
    if (!PreferencesService.instance.isPanicExitEnabled) return;
    
    final now = DateTime.now();
    if (_lastDoubleTap != null &&
        now.difference(_lastDoubleTap!).inMilliseconds < 500) {
      // Double-tap detected within 500ms
      HapticFeedback.heavyImpact();
      context.go(AppRoutes.panicExit);
    }
    _lastDoubleTap = now;
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'nav.catalog'.tr(),
                isSelected: _currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _NavItem(
                icon: Icons.shuffle_outlined,
                activeIcon: Icons.shuffle,
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
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: 'nav.progress'.tr(),
                isSelected: _currentIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
              _NavItem(
                icon: Icons.more_horiz_outlined,
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
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.bottomNavigationBarTheme.unselectedItemColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
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
      backgroundColor: AppColors.burgundy.withOpacity(0.9),
      onPressed: onPressed,
      tooltip: 'consent.safe_word'.tr(),
      child: const Icon(
        Icons.pause_circle_outline,
        color: AppColors.cream,
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
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_filled,
                size: 80,
                color: AppColors.blush,
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
                  color: AppColors.grey400,
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
                  style: const TextStyle(color: AppColors.grey500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
