import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../data/services/pin_hasher.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/user_data_sync_service.dart';
import '../../../shared/widgets/brand.dart';

/// PIN entry/creation screen
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';
  String? _firstPin; // For confirmation during creation
  bool _isCreating = false;
  bool _isConfirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final prefs = PreferencesService.instance;
    final isPinEnabled = prefs.isPinEnabled;
    _isCreating = isPinEnabled && prefs.pinHash == null;
  }

  void _onNumberPressed(int number) {
    if (_enteredPin.length >= 4) return;

    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += number.toString();
      _error = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;

    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _error = null;
    });
  }

  Future<void> _verifyPin() async {
    if (_isCreating) {
      if (_isConfirming) {
        // Confirm PIN matches
        if (_enteredPin == _firstPin) {
          // Save PIN hash (per-device salt + PBKDF2)
          final salt = await _ensureDeviceSalt();
          final hash = PinHasher.hash(_enteredPin, salt);
          await PreferencesService.instance.setPinHash(hash);
          await PreferencesService.instance.setPinEnabled(true);
          UserDataSyncService.instance.syncSettingsPatch({'pin_enabled': true});
          _onAuthenticationSuccess();
        } else {
          setState(() {
            _error = 'pin.pins_dont_match'.tr();
            _enteredPin = '';
            _isConfirming = false;
            _firstPin = null;
          });
          HapticFeedback.heavyImpact();
        }
      } else {
        // First entry, ask for confirmation
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      }
    } else {
      // Verify existing PIN
      final ok = await _verifyAgainstStored(_enteredPin);

      if (ok) {
        _onAuthenticationSuccess();
      } else {
        setState(() {
          _error = 'pin.wrong_pin'.tr();
          _enteredPin = '';
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  /// Verifies [pin] against the stored hash, transparently upgrading a legacy
  /// (global-salt sha256) hash to the v2 scheme on the first correct entry so
  /// existing users are never locked out.
  Future<bool> _verifyAgainstStored(String pin) async {
    final prefs = PreferencesService.instance;
    final stored = prefs.pinHash;
    if (stored == null) return false;

    final salt = await _ensureDeviceSalt();
    final upgraded = PinHasher.verifyAndUpgrade(pin, stored, salt);
    if (upgraded == null) return false;

    if (upgraded != stored) {
      // Legacy hash matched — persist the migration.
      await prefs.setPinHash(upgraded);
    }
    return true;
  }

  /// Reads the per-device salt, creating a cryptographically-random one the
  /// first time.
  Future<String> _ensureDeviceSalt() async {
    final prefs = PreferencesService.instance;
    final existing = prefs.pinSalt;
    if (existing != null && existing.isNotEmpty) return existing;

    final fresh = PinHasher.generateSalt();
    await prefs.setPinSalt(fresh);
    return fresh;
  }

  void _onAuthenticationSuccess() {
    HapticFeedback.mediumImpact();
    PreferencesService.instance.setSessionAuthenticated(true);

    if (!PreferencesService.instance.hasCompletedOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.catalog);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      PreferencesService.instance.setSessionAuthenticated(false);
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      debugPrint('Errore logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCreating
        ? (_isConfirming ? 'pin.confirm_pin'.tr() : 'pin.create_pin'.tr())
        : 'pin.enter_pin'.tr();

    return Scaffold(
      body: VelvetBackground(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              const BrandMark(size: 34),
              const SizedBox(height: 28),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: AppDurations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 11),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.champagne
                          : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? AppColors.error
                            : isFilled
                                ? AppColors.champagne
                                : AppColors.outline,
                        width: 1.2,
                      ),
                    ),
                  );
                }),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ],

              const Spacer(),

              // Number pad
              _buildNumberPad(),

              const SizedBox(height: 24),

              const Spacer(),

              // Logout
              TextButton(
                onPressed: _logout,
                style: TextButton.styleFrom(foregroundColor: AppColors.mist),
                child: Text('settings.logout_and_disconnect'.tr()),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [4, 5, 6].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [7, 8, 9].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 76), // Empty space
            _NumberButton(
              number: 0,
              onPressed: () => _onNumberPressed(0),
            ),
            SizedBox(
              width: 76,
              height: 76,
              child: IconButton(
                onPressed: _onBackspace,
                icon: const Icon(Icons.backspace_outlined,
                    color: AppColors.mist),
                iconSize: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final VoidCallback onPressed;

  const _NumberButton({
    required this.number,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(side: BorderSide(color: AppColors.hairline)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontFamily: AppTypography.displayFont,
                fontFeatures: AppTypography.lining,
                fontSize: 30,
                fontWeight: FontWeight.w400,
                color: AppColors.ivory,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
