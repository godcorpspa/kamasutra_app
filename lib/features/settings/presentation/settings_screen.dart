import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/models/user_data.dart';
import '../../../data/providers/user_data_provider.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/firebase_user_service.dart';

/// Settings screen - uses Firebase for synced settings, local for security
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  
  // LOCAL-ONLY privacy settings (never synced)
  bool _isPinEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isDiscreteIconEnabled = false;
  bool _isPanicExitEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  void _loadLocalSettings() {
    final prefs = PreferencesService.instance;
    setState(() {
      _isPinEnabled = prefs.isPinEnabled;
      _isBiometricEnabled = prefs.isBiometricEnabled;
      _isDiscreteIconEnabled = prefs.isDiscreteIconEnabled;
      _isPanicExitEnabled = prefs.isPanicExitEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch Firebase settings for synced preferences
    final settingsAsync = ref.watch(userSettingsStreamProvider);
    
    return Scaffold(
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) => _buildContent(settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildContent(const UserSettings()), // Fallback to defaults
        ),
      ),
    );
  }

  Widget _buildContent(UserSettings settings) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'settings.title'.tr(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),

        // Privacy section (LOCAL ONLY)
        _buildSectionHeader('settings.privacy'.tr()),
        SliverToBoxAdapter(
          child: _buildPrivacySection(),
        ),

        // Preferences section (SYNCED TO FIREBASE)
        _buildSectionHeader('settings.preferences'.tr()),
        SliverToBoxAdapter(
          child: _buildPreferencesSection(settings),
        ),

        // Data section
        _buildSectionHeader('settings.data'.tr()),
        SliverToBoxAdapter(
          child: _buildDataSection(),
        ),

        // About section
        _buildSectionHeader('settings.about'.tr()),
        SliverToBoxAdapter(
          child: _buildAboutSection(),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.burgundy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============ PRIVACY (LOCAL ONLY) ============
  
  Widget _buildPrivacySection() {
    return Column(
      children: [
        _buildSwitchTile(
          icon: Icons.lock,
          title: 'settings.pin_lock'.tr(),
          subtitle: _isPinEnabled 
              ? 'PIN attivo' 
              : 'Proteggi l\'accesso con PIN',
          value: _isPinEnabled,
          onChanged: (value) async {
            if (value) {
              await PreferencesService.instance.setPinEnabled(true);
            } else {
              await PreferencesService.instance.setPinEnabled(false);
              await PreferencesService.instance.setPinHash(null);
            }
            setState(() => _isPinEnabled = value);
          },
        ),
        
        if (_isPinEnabled)
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: 'settings.biometric'.tr(),
            subtitle: 'Face ID / Touch ID',
            value: _isBiometricEnabled,
            onChanged: (value) async {
              await PreferencesService.instance.setBiometricEnabled(value);
              setState(() => _isBiometricEnabled = value);
            },
          ),
        
        _buildSwitchTile(
          icon: Icons.visibility_off,
          title: 'settings.discrete_icon'.tr(),
          subtitle: 'Icona generica nella home',
          value: _isDiscreteIconEnabled,
          onChanged: (value) async {
            await PreferencesService.instance.setDiscreteIconEnabled(value);
            setState(() => _isDiscreteIconEnabled = value);
          },
        ),
        
        _buildSwitchTile(
          icon: Icons.emergency,
          title: 'settings.panic_exit'.tr(),
          subtitle: 'Doppio tap per uscita rapida',
          value: _isPanicExitEnabled,
          onChanged: (value) async {
            await PreferencesService.instance.setPanicExitEnabled(value);
            setState(() => _isPanicExitEnabled = value);
          },
        ),
      ],
    );
  }

  // ============ PREFERENCES (SYNCED TO FIREBASE) ============

  Widget _buildPreferencesSection(UserSettings settings) {
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    
    return Column(
      children: [
        // Language
        _buildListTile(
          icon: Icons.language,
          title: 'settings.language'.tr(),
          subtitle: context.locale.languageCode == 'it' ? 'Italiano' : 'English',
          onTap: () => _showLanguageDialog(settings, settingsNotifier),
        ),
        
        // Default intensity
        _buildListTile(
          icon: Icons.local_fire_department,
          title: 'settings.default_intensity'.tr(),
          subtitle: _getIntensityLabel(settings.defaultIntensity),
          onTap: () => _showIntensityDialog(settings, settingsNotifier),
        ),
        
        // Illustration style
        _buildListTile(
          icon: Icons.brush,
          title: 'settings.illustration_style'.tr(),
          subtitle: _getStyleLabel(settings.illustrationStyle),
          onTap: () => _showStyleDialog(settings, settingsNotifier),
        ),
        
        // Sound effects
        _buildSwitchTile(
          icon: Icons.volume_up,
          title: 'settings.sound_effects'.tr(),
          subtitle: 'Effetti sonori durante i giochi',
          value: settings.soundEffects,
          onChanged: (value) => settingsNotifier.updateSoundEffects(value),
        ),
        
        // Haptic feedback
        _buildSwitchTile(
          icon: Icons.vibration,
          title: 'settings.haptic_feedback'.tr(),
          subtitle: 'Vibrazioni tattili',
          value: settings.hapticFeedback,
          onChanged: (value) => settingsNotifier.updateHapticFeedback(value),
        ),
        
        // Consent interval
        _buildListTile(
          icon: Icons.timer,
          title: 'settings.consent_interval'.tr(),
          subtitle: 'Ogni ${settings.consentCheckInInterval} minuti',
          onTap: () => _showConsentIntervalDialog(settings, settingsNotifier),
        ),
      ],
    );
  }

  // ============ DATA ============

  Widget _buildDataSection() {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.history,
          title: 'settings.clear_history'.tr(),
          subtitle: 'Elimina la cronologia delle posizioni',
          onTap: () => _showClearHistoryDialog(),
        ),
        _buildListTile(
          icon: Icons.delete_forever,
          title: 'settings.clear_all_data'.tr(),
          subtitle: 'Elimina tutti i dati salvati',
          onTap: () => _showClearAllDataDialog(),
          isDestructive: true,
        ),
        _buildListTile(
          icon: Icons.cloud_sync,
          title: 'Sincronizza dati',
          subtitle: 'I tuoi dati sono sincronizzati automaticamente',
          onTap: null,
        ),
      ],
    );
  }

  // ============ ABOUT ============

  Widget _buildAboutSection() {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.info,
          title: 'settings.version'.tr(),
          subtitle: '1.0.0',
          onTap: null,
        ),
        _buildListTile(
          icon: Icons.feedback,
          title: 'settings.feedback'.tr(),
          subtitle: 'Inviaci i tuoi suggerimenti',
          onTap: () {
            // TODO: Open feedback
          },
        ),
        _buildListTile(
          icon: Icons.star,
          title: 'settings.rate_app'.tr(),
          subtitle: 'Lascia una recensione',
          onTap: () {
            // TODO: Open store
          },
        ),
        _buildListTile(
          icon: Icons.privacy_tip,
          title: 'settings.privacy_policy'.tr(),
          onTap: () {
            // TODO: Open privacy policy
          },
        ),
      ],
    );
  }

  // ============ DIALOGS ============

  void _showLanguageDialog(UserSettings settings, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.language'.tr()),
        children: [
          SimpleDialogOption(
            onPressed: () {
              context.setLocale(const Locale('it'));
              notifier.updateLocale('it');
              Navigator.pop(context);
            },
            child: ListTile(
              leading: const Text('🇮🇹', style: TextStyle(fontSize: 24)),
              title: const Text('Italiano'),
              trailing: settings.locale == 'it'
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.setLocale(const Locale('en'));
              notifier.updateLocale('en');
              Navigator.pop(context);
            },
            child: ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: settings.locale == 'en'
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showIntensityDialog(UserSettings settings, SettingsNotifier notifier) {
    final intensities = ['soft', 'spicy', 'extraSpicy'];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.default_intensity'.tr()),
        children: intensities.map((intensity) {
          return SimpleDialogOption(
            onPressed: () {
              notifier.updateDefaultIntensity(intensity);
              Navigator.pop(context);
            },
            child: ListTile(
              title: Text(_getIntensityLabel(intensity)),
              trailing: settings.defaultIntensity == intensity
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStyleDialog(UserSettings settings, SettingsNotifier notifier) {
    final styles = ['line_art', 'silhouette', 'geometric'];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.illustration_style'.tr()),
        children: styles.map((style) {
          return SimpleDialogOption(
            onPressed: () {
              notifier.updateIllustrationStyle(style);
              Navigator.pop(context);
            },
            child: ListTile(
              title: Text(_getStyleLabel(style)),
              trailing: settings.illustrationStyle == style
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showConsentIntervalDialog(UserSettings settings, SettingsNotifier notifier) {
    final intervals = [10, 15, 20, 30, 45, 60];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.consent_interval'.tr()),
        children: intervals.map((minutes) {
          return SimpleDialogOption(
            onPressed: () {
              notifier.updateConsentCheckInInterval(minutes);
              Navigator.pop(context);
            },
            child: ListTile(
              title: Text('Ogni $minutes minuti'),
              trailing: settings.consentCheckInInterval == minutes
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.clear_history'.tr()),
        content: const Text(
          'Sei sicuro di voler eliminare tutta la cronologia? '
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseUserService().clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cronologia eliminata'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.clear_all_data'.tr()),
        content: const Text(
          'Sei sicuro di voler eliminare tutti i dati? '
          'Questo include preferenze, cronologia, badge e progressi. '
          'L\'azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              // Clear Firebase data
              await FirebaseUserService().clearAllData();
              // Clear local data too
              await PreferencesService.instance.clearEverything();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tutti i dati eliminati'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  // ============ HELPERS ============

  String _getIntensityLabel(String intensity) {
    switch (intensity) {
      case 'soft':
        return '🌸 Soft';
      case 'spicy':
        return '🌶️ Spicy';
      case 'extraSpicy':
        return '🔥 Extra Spicy';
      default:
        return intensity;
    }
  }

  String _getStyleLabel(String style) {
    switch (style) {
      case 'line_art':
        return 'Line Art (elegante)';
      case 'silhouette':
        return 'Silhouette (minimalista)';
      case 'geometric':
        return 'Geometrico (astratto)';
      default:
        return style;
    }
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.burgundy.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: AppColors.burgundy, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          HapticFeedback.lightImpact();
          onChanged(newValue);
        },
        activeColor: AppColors.burgundy,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDestructive ? AppColors.error : AppColors.burgundy).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.burgundy,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDestructive ? AppColors.error.withOpacity(0.7) : null,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            )
          : null,
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
    );
  }
}
