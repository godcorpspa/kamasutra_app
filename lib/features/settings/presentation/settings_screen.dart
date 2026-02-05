import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/models/game.dart';

/// Settings screen - all app preferences and configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  
  // Privacy settings
  bool _isPinEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isDiscreteIconEnabled = false;
  bool _isPanicExitEnabled = true;
  
  // Preferences
  GameIntensity _defaultIntensity = GameIntensity.soft;
  String _illustrationStyle = 'line_art';
  bool _soundEffects = true;
  bool _hapticFeedback = true;
  int _consentInterval = 15;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final prefs = PreferencesService.instance;
    setState(() {
      _isPinEnabled = prefs.isPinEnabled;
      _isBiometricEnabled = prefs.isBiometricEnabled;
      _isDiscreteIconEnabled = prefs.isDiscreteIconEnabled;
      _isPanicExitEnabled = prefs.isPanicExitEnabled;
      _defaultIntensity = GameIntensity.values.firstWhere(
        (i) => i.name == prefs.defaultIntensity,
        orElse: () => GameIntensity.soft,
      );
      _illustrationStyle = prefs.illustrationStyle;
      _soundEffects = prefs.areSoundEffectsEnabled;
      _hapticFeedback = prefs.isHapticFeedbackEnabled;
      _consentInterval = prefs.consentCheckInInterval;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
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

            // Privacy section
            _buildSectionHeader('settings.privacy'.tr()),
            SliverToBoxAdapter(
              child: _buildPrivacySection(),
            ),

            // Preferences section
            _buildSectionHeader('settings.preferences'.tr()),
            SliverToBoxAdapter(
              child: _buildPreferencesSection(),
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
        ),
      ),
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
              // Navigate to PIN creation
              // For now just toggle
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

  Widget _buildPreferencesSection() {
    return Column(
      children: [
        // Language
        _buildListTile(
          icon: Icons.language,
          title: 'settings.language'.tr(),
          subtitle: context.locale.languageCode == 'it' ? 'Italiano' : 'English',
          onTap: () => _showLanguageDialog(),
        ),
        
        // Default intensity
        _buildListTile(
          icon: Icons.local_fire_department,
          title: 'settings.default_intensity'.tr(),
          subtitle: _getIntensityLabel(_defaultIntensity),
          onTap: () => _showIntensityDialog(),
        ),
        
        // Illustration style
        _buildListTile(
          icon: Icons.brush,
          title: 'settings.illustration_style'.tr(),
          subtitle: _getStyleLabel(_illustrationStyle),
          onTap: () => _showStyleDialog(),
        ),
        
        // Sound effects
        _buildSwitchTile(
          icon: Icons.volume_up,
          title: 'settings.sound_effects'.tr(),
          subtitle: 'Effetti sonori durante i giochi',
          value: _soundEffects,
          onChanged: (value) async {
            await PreferencesService.instance.setSoundEffectsEnabled(value);
            setState(() => _soundEffects = value);
          },
        ),
        
        // Haptic feedback
        _buildSwitchTile(
          icon: Icons.vibration,
          title: 'settings.haptic_feedback'.tr(),
          subtitle: 'Vibrazioni tattili',
          value: _hapticFeedback,
          onChanged: (value) async {
            await PreferencesService.instance.setHapticFeedbackEnabled(value);
            setState(() => _hapticFeedback = value);
          },
        ),
        
        // Consent interval
        _buildListTile(
          icon: Icons.timer,
          title: 'settings.consent_interval'.tr(),
          subtitle: 'Ogni $_consentInterval minuti',
          onTap: () => _showConsentIntervalDialog(),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.history,
          title: 'settings.clear_history'.tr(),
          subtitle: 'Elimina la cronologia delle esplorazioni',
          onTap: () => _showClearHistoryDialog(),
        ),
        
        _buildListTile(
          icon: Icons.delete_forever,
          title: 'settings.clear_all_data'.tr(),
          subtitle: 'Ripristina tutte le impostazioni',
          onTap: () => _showClearAllDataDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
  return Column(
    children: [
      // AGGIUNGI LOGOUT ALL'INIZIO
      _buildListTile(
        icon: Icons.logout,
        title: 'Esci dall\'account',
        subtitle: 'Disconnetti e torna al login',
        onTap: () => _showLogoutDialog(),
        isDestructive: true,
      ),
      
      const Divider(indent: 72),
      
      _buildListTile(
        icon: Icons.info_outline,
        title: 'settings.version'.tr(),
        subtitle: 'v1.0.0',
      ),
      _buildListTile(
        icon: Icons.description_outlined,
        title: 'settings.privacy_policy'.tr(),
        onTap: () {
          // Open privacy policy
        },
      ),
      _buildListTile(
        icon: Icons.gavel_outlined,
        title: 'settings.terms'.tr(),
        onTap: () {
          // Open terms
        },
      ),
      _buildListTile(
        icon: Icons.email_outlined,
        title: 'settings.contact'.tr(),
        subtitle: 'Feedback e suggerimenti',
        onTap: () {
          // Open email
        },
      ),
    ],
  );
}

// AGGIUNGI QUESTO NUOVO METODO
void _showLogoutDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Esci dall\'account'),
      content: const Text(
        'Sei sicuro di voler uscire? Dovrai effettuare nuovamente l\'accesso.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _performLogout();
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Esci'),
        ),
      ],
    ),
  );
}

Future<void> _performLogout() async {
  try {
    // Logout da Firebase
    await FirebaseAuth.instance.signOut();
    
    // Logout da Google se era connesso
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
    
    // Reset sessione locale
    PreferencesService.instance.setSessionAuthenticated(false);
    
    // Naviga al login
    if (mounted) {
      context.go(AppRoutes.login);
    }
  } catch (e) {
    debugPrint('Errore logout: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il logout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.burgundy.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          color: AppColors.burgundy,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          HapticFeedback.lightImpact();
          onChanged(newValue);
        },
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

  String _getIntensityLabel(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return '🌸 Soft';
      case GameIntensity.spicy:
        return '🌶️ Spicy';
      case GameIntensity.extraSpicy:
        return '🔥 Extra Spicy';
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.language'.tr()),
        children: [
          SimpleDialogOption(
            onPressed: () {
              context.setLocale(const Locale('it'));
              Navigator.pop(context);
              setState(() {});
            },
            child: ListTile(
              leading: const Text('🇮🇹', style: TextStyle(fontSize: 24)),
              title: const Text('Italiano'),
              trailing: context.locale.languageCode == 'it'
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.setLocale(const Locale('en'));
              Navigator.pop(context);
              setState(() {});
            },
            child: ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: context.locale.languageCode == 'en'
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showIntensityDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.default_intensity'.tr()),
        children: GameIntensity.values.map((intensity) {
          return SimpleDialogOption(
            onPressed: () async {
              await PreferencesService.instance.setDefaultIntensity(intensity.name);
              setState(() => _defaultIntensity = intensity);
              Navigator.pop(context);
            },
            child: ListTile(
              title: Text(_getIntensityLabel(intensity)),
              trailing: _defaultIntensity == intensity
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStyleDialog() {
    final styles = ['line_art', 'silhouette', 'geometric'];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.illustration_style'.tr()),
        children: styles.map((style) {
          return SimpleDialogOption(
            onPressed: () async {
              await PreferencesService.instance.setIllustrationStyle(style);
              setState(() => _illustrationStyle = style);
              Navigator.pop(context);
            },
            child: ListTile(
              title: Text(_getStyleLabel(style)),
              trailing: _illustrationStyle == style
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showConsentIntervalDialog() {
    final intervals = [10, 15, 20, 30, 45, 60];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('settings.consent_interval'.tr()),
        children: intervals.map((minutes) {
          return SimpleDialogOption(
            onPressed: () async {
              await PreferencesService.instance.setConsentCheckInInterval(minutes);
              setState(() => _consentInterval = minutes);
              Navigator.pop(context);
            },
            child: ListTile(
              title: Text('Ogni $minutes minuti'),
              trailing: _consentInterval == minutes
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
              await PreferencesService.instance.clearHistory();
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
}
