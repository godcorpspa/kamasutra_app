import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../data/local/preferences_service.dart';

/// Age verification gate screen
class AgeGateScreen extends StatelessWidget {
  const AgeGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.burgundy.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  size: 50,
                  color: AppColors.burgundy,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                'age_gate.title'.tr(),
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'age_gate.subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Question
              Text(
                'age_gate.question'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onConfirm(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('age_gate.confirm'.tr()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Deny button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _onDeny(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('age_gate.deny'.tr()),
                ),
              ),
              
              const Spacer(),
              
              // Legal notice
              Text(
                'age_gate.legal_notice'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm(BuildContext context) async {
    HapticFeedback.mediumImpact();
    
    // Save age verification
    await PreferencesService.instance.setAgeVerified(true);
    
    // Set first launch date if not set
    if (PreferencesService.instance.firstLaunchDate == null) {
      await PreferencesService.instance.setFirstLaunchDate(DateTime.now());
    }
    
    if (context.mounted) {
      // Check if PIN is enabled
      if (PreferencesService.instance.isPinEnabled) {
        context.go(AppRoutes.pin);
      } else if (!PreferencesService.instance.hasCompletedOnboarding) {
        context.go(AppRoutes.onboarding);
      } else {
        context.go(AppRoutes.catalog);
      }
    }
  }

  void _onDeny(BuildContext context) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('age_gate.title'.tr()),
        content: Text('age_gate.denied_message'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Close app or show blocked state
              SystemNavigator.pop();
            },
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }
}
