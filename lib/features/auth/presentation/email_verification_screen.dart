import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../shared/utils/auth_error_text.dart';
import '../../../shared/widgets/brand.dart';
import '../../../data/services/preferences_service.dart';

/// Email-verification gate shown immediately after a fresh
/// createUserWithEmailAndPassword. The user can:
///  * tap "I verified" — we reload the Firebase user and proceed if the
///    server now reports `emailVerified == true`,
///  * resend the verification email (with a 60-second cooldown to avoid
///    Firebase's hourly server-side rate limit kicking in),
///  * cancel — we sign out and delete the just-created unverified account,
///    so a typo'd email doesn't leave a junk account behind.
///
/// While the screen is open we poll `user.reload()` every 4 seconds, so the
/// flow advances automatically as soon as the user clicks the email link.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Duration _pollInterval = Duration(seconds: 4);
  static const Duration _resendCooldown = Duration(seconds: 60);

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownSecondsLeft = 0;
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkVerified());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified({bool fromUserTap = false}) async {
    if (_isChecking) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    setState(() => _isChecking = true);
    try {
      await user.reload();
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh != null && fresh.emailVerified) {
        _pollTimer?.cancel();
        if (mounted) _navigateAfterVerification();
        return;
      }
      if (fromUserTap && mounted) {
        setState(() {
          _errorMessage = 'auth.verify_not_yet'.tr();
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = authErrorText(e.code));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldownSecondsLeft > 0) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.sendEmailVerification();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auth.verify_email_resent'.tr())),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = authErrorText(e.code));
      }
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSecondsLeft = _resendCooldown.inSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSecondsLeft = _cooldownSecondsLeft - 1;
        if (_cooldownSecondsLeft <= 0) timer.cancel();
      });
    });
  }

  Future<void> _cancelAndDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    _pollTimer?.cancel();
    try {
      // Best-effort: delete the just-created unverified account so a typo'd
      // email doesn't leave a junk record behind. If Firebase requires recent
      // login we fall back to a plain sign-out.
      await user?.delete();
    } on FirebaseAuthException {
      await FirebaseAuth.instance.signOut();
    }
    if (mounted) context.go(AppRoutes.login);
  }

  void _navigateAfterVerification() {
    final prefs = PreferencesService.instance;
    if (!prefs.isAgeVerified) {
      context.go(AppRoutes.ageGate);
    } else if (prefs.isPinEnabled && !prefs.isSessionAuthenticated) {
      context.go(AppRoutes.pin);
    } else if (!prefs.hasCompletedOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.catalog);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final canResend = _cooldownSecondsLeft <= 0;

    return Scaffold(
      body: VelvetBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.champagne.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined,
                        size: 36, color: AppColors.champagne),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'auth.verify_email_title'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'auth.verify_email_body'.tr(namedArgs: {'email': email}),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.mist),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isChecking
                        ? null
                        : () => _checkVerified(fromUserTap: true),
                    child: _isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('auth.verify_check_now'.tr()),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: canResend ? _resend : null,
                    child: Text(canResend
                        ? 'auth.verify_resend'.tr()
                        : 'auth.verify_resend_in'.tr(
                            namedArgs: {'seconds': '$_cooldownSecondsLeft'})),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _cancelAndDeleteAccount,
                  style: TextButton.styleFrom(foregroundColor: AppColors.mist),
                  child: Text('auth.verify_cancel'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
