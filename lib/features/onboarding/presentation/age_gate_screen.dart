import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/user_data_sync_service.dart';
import '../../../shared/widgets/brand.dart';

/// Age verification gate screen
class AgeGateScreen extends StatelessWidget {
  const AgeGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VelvetBackground(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              const BrandMark(size: 48),

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
                  color: AppColors.mist,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Question
              Text(
                'age_gate.question'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onConfirm(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
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
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: Text('age_gate.deny'.tr()),
                ),
              ),
              
              const Spacer(),
              
              // Legal notice
              Text(
                'age_gate.legal_notice'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.smoke,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _onConfirm(BuildContext context) async {
    HapticFeedback.mediumImpact();
    
    // Save age verification
    await PreferencesService.instance.setAgeVerified(true);
    UserDataSyncService.instance.syncSettingsPatch({'age_verified': true});
    
    // Set first launch date if not set
    if (PreferencesService.instance.firstLaunchDate == null) {
      await PreferencesService.instance.setFirstLaunchDate(DateTime.now());
      UserDataSyncService.instance.syncSettingsPatch({'first_launch_date': PreferencesService.instance.firstLaunchDate?.toIso8601String()});
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
