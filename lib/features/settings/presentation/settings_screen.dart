import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/user_data_sync_service.dart';
import '../../../data/services/audio_service.dart';

/// Settings screen - all app preferences and configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  
  // Privacy settings
  bool _isPinEnabled = false;

  // Preferences
  bool _soundEffects = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final prefs = PreferencesService.instance;
    setState(() {
      _isPinEnabled = prefs.isPinEnabled;
      _soundEffects = prefs.areSoundEffectsEnabled;
      _hapticFeedback = prefs.isHapticFeedbackEnabled;
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

            // Account section
            _buildSectionHeader('settings.account_details'.tr()),
            SliverToBoxAdapter(
              child: _buildAccountSection(),
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

  String _getLanguageName(String code) {
    switch (code) {
      case 'it': return 'Italiano';
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'pt': return 'Português';
      default: return code;
    }
  }

  Widget _buildPrivacySection() {
    return Column(
      children: [
        _buildSwitchTile(
          icon: Icons.lock,
          title: 'settings.pin_lock'.tr(),
          subtitle: _isPinEnabled
              ? 'settings.pin_active'.tr()
              : 'settings.pin_protect'.tr(),
          value: _isPinEnabled,
          onChanged: (value) async {
            if (value) {
              await PreferencesService.instance.setPinEnabled(true);
              UserDataSyncService.instance.syncSettingsPatch({'pin_enabled': true});
            } else {
              await PreferencesService.instance.setPinEnabled(false);
              await PreferencesService.instance.setPinHash(null);
              UserDataSyncService.instance.syncSettingsPatch({'pin_enabled': false});
            }
            setState(() => _isPinEnabled = value);
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '—';

    return Column(
      children: [
        // Email
        _buildListTile(
          icon: Icons.email_outlined,
          title: 'settings_extra.email_label'.tr(),
          subtitle: email,
        ),

        // Change password (always visible)
        _buildListTile(
          icon: Icons.key_outlined,
          title: 'settings_extra.change_password'.tr(),
          subtitle: 'settings_extra.change_password_subtitle'.tr(),
          onTap: () => _showChangePasswordDialog(),
        ),

        // Delete account
        _buildListTile(
          icon: Icons.person_remove_outlined,
          title: 'settings_extra.delete_account'.tr(),
          subtitle: 'settings_extra.delete_account_subtitle'.tr(),
          onTap: () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings_extra.change_password'.tr()),
        content: Text(
          'settings_extra.change_password_desc'.tr(namedArgs: {'email': user!.email!}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: user!.email!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings_extra.email_sent'.tr(namedArgs: {'email': user.email!})),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings_extra.send_email_error'.tr()),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('settings_extra.send_email'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings_extra.delete_account'.tr()),
        content: Text(
          'settings_extra.delete_confirm_text'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _performDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('settings_extra.delete_account'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1) Delete cloud data
      await UserDataSyncService.instance.deleteCloudUserCompletely();

      // 2) Delete Firebase Auth account
      await user.delete();

      // 3) Clear local data
      await PreferencesService.instance.clearEverything();
      PreferencesService.instance.setSessionAuthenticated(false);

      // 4) Sign out Google if needed
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // 5) Go to login
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Need reauthentication
        _showReauthDialog();
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('settings_extra.error_delete_account'.tr()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('settings_extra.delete_error'.tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showReauthDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');

    if (isGoogleUser) {
      // Google reauthentication
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('settings_extra.confirm_identity'.tr()),
          content: Text(
            'settings_extra.reauth_google_desc'.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _reauthWithGoogleAndDelete();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text('settings_extra.sign_in_google'.tr()),
            ),
          ],
        ),
      );
    } else {
      // Email/password reauthentication
      final passwordController = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Conferma identità'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Per motivi di sicurezza, inserisci la tua password per confermare l\'eliminazione.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(dialogContext);
              },
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text;
                passwordController.dispose();
                Navigator.pop(dialogContext);
                await _reauthWithPasswordAndDelete(password);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Conferma ed elimina'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _reauthWithGoogleAndDelete() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = FirebaseAuth.instance.currentUser!;
      await user.reauthenticateWithCredential(credential);
      await _performDeleteAccount();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Errore durante la riautenticazione'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reauthWithPasswordAndDelete(String password) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await _performDeleteAccount();
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'wrong-password'
          ? 'Password errata'
          : 'Errore: ${e.message ?? 'riautenticazione fallita'}';
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Errore durante la riautenticazione'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        
        // Sound effects
        _buildSwitchTile(
          icon: Icons.volume_up,
          title: 'settings.sound_effects'.tr(),
          subtitle: 'Effetti sonori durante i giochi',
          value: _soundEffects,
          onChanged: (value) async {
            await PreferencesService.instance.setSoundEffectsEnabled(value);
            UserDataSyncService.instance.syncSettingsPatch({'sound_effects': value});
            AudioService.instance.setEnabled(value);
            if (value) {
              AudioService.instance.playToggleOn();
            }
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
            UserDataSyncService.instance.syncSettingsPatch({'haptic_feedback': value});
            setState(() => _hapticFeedback = value);
          },
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
          onTap: () => _showPrivacyPolicy(),
        ),
        _buildListTile(
          icon: Icons.gavel_outlined,
          title: 'settings.terms'.tr(),
          onTap: () => _showTermsOfService(),
        ),
        _buildListTile(
          icon: Icons.email_outlined,
          title: 'settings.contact'.tr(),
          subtitle: 'Segnala un bug o invia un suggerimento',
          onTap: () => _showContactOptions(),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Esci dall\'account'),
        content: const Text(
          'Sei sicuro di voler uscire? Dovrai effettuare nuovamente l\'accesso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
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
      await FirebaseAuth.instance.signOut();

      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      PreferencesService.instance.setSessionAuthenticated(false);

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
          SimpleDialogOption(
            onPressed: () {
              context.setLocale(const Locale('es'));
              Navigator.pop(context);
              setState(() {});
            },
            child: ListTile(
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: const Text('Español'),
              trailing: context.locale.languageCode == 'es'
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.setLocale(const Locale('fr'));
              Navigator.pop(context);
              setState(() {});
            },
            child: ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Français'),
              trailing: context.locale.languageCode == 'fr'
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.setLocale(const Locale('pt'));
              Navigator.pop(context);
              setState(() {});
            },
            child: ListTile(
              leading: const Text('🇵🇹', style: TextStyle(fontSize: 24)),
              title: const Text('Português'),
              trailing: context.locale.languageCode == 'pt'
                  ? const Icon(Icons.check, color: AppColors.burgundy)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.clear_history'.tr()),
        content: const Text(
          'Sei sicuro di voler eliminare tutta la cronologia? '
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await PreferencesService.instance.clearHistory();
                await PreferencesService.instance.setTriedPositionIds([]);
                await UserDataSyncService.instance.clearCloudHistory();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Cronologia eliminata'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Errore durante l\'eliminazione'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'settings.privacy_policy'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  _privacyPolicyText(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'settings.terms'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  _termsOfServiceText(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                child: Text(
                  'Contattaci',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, color: AppColors.spicy),
                title: const Text('Segnala un bug'),
                subtitle: const Text('Hai trovato un problema? Faccelo sapere'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendEmail(
                    subject: '[BUG] - Kamasutra & Couple Games v1.0.0',
                    body: 'Descrivi il problema:\n\nDispositivo:\nVersione OS:\nPassaggi per riprodurlo:\n',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: AppColors.gold),
                title: const Text('Invia un suggerimento'),
                subtitle: const Text('Hai un\'idea per migliorare l\'app?'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendEmail(
                    subject: '[SUGGERIMENTO] - Kamasutra & Couple Games',
                    body: 'Il mio suggerimento:\n\n',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline, color: AppColors.burgundy),
                title: const Text('Valuta l\'app'),
                subtitle: const Text('Ti piace l\'app? Lascia una recensione'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendEmail(
                    subject: '[FEEDBACK] - Kamasutra & Couple Games',
                    body: 'La mia opinione sull\'app:\n\n',
                  );
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'support@kamasutraapp.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmail({required String subject, String body = ''}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@kamasutraapp.com',
      queryParameters: {'subject': subject, 'body': body},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scrivici a support@kamasutraapp.com'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scrivici a support@kamasutraapp.com'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _privacyPolicyText() {
    return '''Privacy Policy - Kamasutra & Couple Games

Ultimo aggiornamento: 19 febbraio 2026

1. Introduzione
La tua privacy è importante per noi. Questa Privacy Policy spiega come raccogliamo, utilizziamo e proteggiamo i tuoi dati personali.

2. Dati raccolti
- Dati di autenticazione: email e nome (se forniti tramite login Google o email).
- Dati di utilizzo: preferenze, cronologia esplorazioni, progressi e badge.
- Dati locali: PIN (hash), impostazioni dell'app.

3. Come utilizziamo i dati
- Per fornire e migliorare il servizio.
- Per sincronizzare i tuoi dati tra dispositivi (opzionale).
- Non vendiamo né condividiamo i tuoi dati con terze parti.

4. Archiviazione e sicurezza
- I dati sensibili (PIN) sono archiviati esclusivamente in locale sul tuo dispositivo.
- I dati cloud sono protetti tramite Firebase con crittografia in transito e a riposo.
- Puoi eliminare tutti i tuoi dati in qualsiasi momento dalle impostazioni.

5. Servizi di terze parti
- Firebase (Google): autenticazione e archiviazione cloud.
- Google Sign-In: accesso opzionale.

6. I tuoi diritti
- Accesso ai tuoi dati personali.
- Cancellazione completa dei dati.
- Portabilità dei dati.
- Revoca del consenso in qualsiasi momento.

7. Contatti
Per domande sulla privacy, contattaci a: support@kamasutraapp.com

8. Modifiche
Ci riserviamo il diritto di aggiornare questa policy. Le modifiche saranno comunicate tramite l'app.''';
  }

  String _termsOfServiceText() {
    return '''Termini di Servizio - Kamasutra & Couple Games

Ultimo aggiornamento: 19 febbraio 2026

1. Accettazione dei termini
Utilizzando l'app, accetti i presenti termini di servizio.

2. Requisiti di età
L'app è destinata esclusivamente a utenti maggiorenni (18+ anni). L'accesso è subordinato alla verifica dell'età.

3. Uso dell'app
- L'app è progettata per coppie adulte consenzienti.
- È vietato qualsiasi uso illegale o non autorizzato.
- Il contenuto è fornito a scopo educativo e di intrattenimento.

4. Account e dati
- Sei responsabile della sicurezza del tuo account.
- Puoi eliminare i tuoi dati in qualsiasi momento.
- La sincronizzazione cloud è opzionale.

5. Proprietà intellettuale
Tutti i contenuti, illustrazioni, testi e design sono protetti da copyright.

6. Limitazione di responsabilità
L'app è fornita "così com'è". Non garantiamo che il servizio sia privo di errori o interruzioni.

7. Consenso e sicurezza
- L'app promuove il consenso reciproco in ogni interazione.
- Le funzionalità di pausa e check-in sono integrate per garantire il comfort di entrambi i partner.

8. Modifiche ai termini
Ci riserviamo il diritto di modificare questi termini. Le modifiche saranno comunicate tramite l'app.

9. Contatti
Per domande sui termini, contattaci a: support@kamasutraapp.com''';
  }

  void _showClearAllDataDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.clear_all_data'.tr()),
        content: const Text(
          'Sei sicuro di voler eliminare tutti i dati? '
          'Questo include preferenze, cronologia, badge e progressi. '
          'L\'azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await PreferencesService.instance.clearEverything();
                await UserDataSyncService.instance.clearCloudUserData();
                _loadSettings();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Tutti i dati eliminati'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Errore durante l\'eliminazione'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
