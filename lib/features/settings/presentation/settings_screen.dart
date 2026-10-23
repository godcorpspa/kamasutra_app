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
import '../../../data/services/auth_service.dart';
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
                  style: Theme.of(context).textTheme.displaySmall,
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
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Text(
          title.toUpperCase(),
          style: AppTypography.eyebrow,
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
    // safeCurrentUser: la schermata è raggiungibile anche in modalità locale
    // (Firebase non inizializzato), dove FirebaseAuth.instance lancerebbe.
    final user = AuthService.safeCurrentUser;
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
    final user = AuthService.safeCurrentUser;
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
    final user = AuthService.safeCurrentUser;
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
    final user = AuthService.safeCurrentUser;
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
          title: Text('settings_extra.confirm_identity'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'settings_extra.reauth_email_desc'.tr(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'settings_extra.password_label'.tr(),
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
              child: Text('settings_extra.confirm_delete'.tr()),
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

      final user = AuthService.safeCurrentUser;
      if (user == null) return;
      await user.reauthenticateWithCredential(credential);
      await _performDeleteAccount();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('settings_extra.reauth_error'.tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reauthWithPasswordAndDelete(String password) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = AuthService.safeCurrentUser;
      if (user?.email == null) return;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await _performDeleteAccount();
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'wrong-password'
          ? 'settings_extra.wrong_password'.tr()
          : 'settings_extra.error_delete_account'.tr();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('settings_extra.reauth_error'.tr()),
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
          subtitle: _getLanguageName(context.locale.languageCode),
          onTap: () => _showLanguageDialog(),
        ),
        
        // Sound effects
        _buildSwitchTile(
          icon: Icons.volume_up,
          title: 'settings.sound_effects'.tr(),
          subtitle: 'settings.sound_effects_desc'.tr(),
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
          subtitle: 'settings.haptic_desc'.tr(),
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
          subtitle: 'settings.clear_history_desc'.tr(),
          onTap: () => _showClearHistoryDialog(),
        ),
        
        _buildListTile(
          icon: Icons.delete_forever,
          title: 'settings.clear_all_data'.tr(),
          subtitle: 'settings.clear_all_data_desc'.tr(),
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
          title: 'settings.logout_and_disconnect'.tr(),
          subtitle: 'settings.logout_disconnect_desc'.tr(),
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
          subtitle: 'settings_extra.contact_subtitle'.tr(),
          onTap: () => _showContactOptions(),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings_extra.logout'.tr()),
        content: Text(
          'settings_extra.logout_desc'.tr(),
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
            child: Text('settings_extra.logout_btn'.tr()),
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
          SnackBar(
            content: Text('settings_extra.logout_error'.tr()),
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
      leading: _TileIcon(icon: icon),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
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
      leading: _TileIcon(icon: icon, isDestructive: isDestructive),
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
                color: isDestructive
                    ? AppColors.error.withOpacity(0.7)
                    : AppColors.mist,
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.smoke, size: 20)
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
                  ? const Icon(Icons.check, color: AppColors.champagne)
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
                  ? const Icon(Icons.check, color: AppColors.champagne)
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
                  ? const Icon(Icons.check, color: AppColors.champagne)
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
                  ? const Icon(Icons.check, color: AppColors.champagne)
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
                  ? const Icon(Icons.check, color: AppColors.champagne)
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
        content: Text(
          'settings_extra.clear_history_confirm'.tr(),
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
                  SnackBar(
                    content: Text('settings_extra.history_deleted'.tr()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('settings_extra.delete_error_generic'.tr()),
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
      // Above the shell's floating nav bar, which would cover the sheet.
      useRootNavigator: true,
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
      // Above the shell's floating nav bar, which would cover the sheet.
      useRootNavigator: true,
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
      // Above the shell's floating nav bar, which would cover the sheet.
      useRootNavigator: true,
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
                  'settings.contact'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, color: AppColors.mist),
                title: Text('settings_extra.report_bug'.tr()),
                subtitle: Text('settings_extra.report_bug_desc'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendEmail(
                    subject: 'settings_extra.email_subject_bug'.tr(),
                    body: 'settings_extra.email_body_bug'.tr(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: AppColors.mist),
                title: Text('settings_extra.send_suggestion'.tr()),
                subtitle: Text('settings_extra.send_suggestion_desc'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendEmail(
                    subject: 'settings_extra.email_subject_suggestion'.tr(),
                    body: 'settings_extra.email_body_suggestion'.tr(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline, color: AppColors.mist),
                title: Text('settings_extra.rate_app'.tr()),
                subtitle: Text('settings_extra.rate_app_desc'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendEmail(
                    subject: 'settings_extra.email_subject_feedback'.tr(),
                    body: 'settings_extra.email_body_feedback'.tr(),
                  );
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'support@kamasutraapp.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.smoke,
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
          SnackBar(
            content: Text('settings_extra.write_to_support'.tr()),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_extra.write_to_support'.tr()),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _privacyPolicyText() => 'settings_extra.privacy_text'.tr();

  String _termsOfServiceText() => 'settings_extra.terms_text'.tr();

  void _showClearAllDataDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.clear_all_data'.tr()),
        content: Text(
          'settings_extra.clear_all_confirm'.tr(),
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
                  SnackBar(
                    content: Text('settings_extra.all_data_deleted'.tr()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('settings_extra.delete_error_generic'.tr()),
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

/// Line icon in a hairline ring — the leading glyph of every settings row.
class _TileIcon extends StatelessWidget {
  final IconData icon;
  final bool isDestructive;

  const _TileIcon({required this.icon, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.mist;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDestructive
              ? AppColors.error.withOpacity(0.35)
              : AppColors.hairline,
        ),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}
