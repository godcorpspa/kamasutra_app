import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/user_data_sync_service.dart';

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
          final hash = await _hashPin(_enteredPin);
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

  // Legacy salt — kept only to verify (and then migrate) PINs created before
  // the per-device salt + PBKDF2 scheme was introduced.
  static const String _legacySalt = 'kamasutra_salt_2024';

  // Number of PBKDF2 iterations. A 4-digit PIN has a tiny keyspace, so this
  // only slows offline guessing; the real protection is keeping the device
  // out of an attacker's hands. Hardware-backed storage is a follow-up.
  static const int _pbkdf2Iterations = 100000;

  /// Verifies [pin] against the stored hash, transparently upgrading a
  /// legacy (global-salt sha256) hash to the new scheme on first success so
  /// existing users are never locked out.
  Future<bool> _verifyAgainstStored(String pin) async {
    final stored = PreferencesService.instance.pinHash;
    if (stored == null) return false;

    if (stored.startsWith('v2:')) {
      final salt = await _ensureDeviceSalt();
      return _constantTimeEquals(stored, await _hashPin(pin, salt: salt));
    }

    // Legacy hash: sha256(pin + global salt).
    final legacy =
        sha256.convert(utf8.encode(pin + _legacySalt)).toString();
    if (_constantTimeEquals(stored, legacy)) {
      // Migrate to the new scheme.
      await PreferencesService.instance.setPinHash(await _hashPin(pin));
      return true;
    }
    return false;
  }

  /// Hashes [pin] with PBKDF2-HMAC-SHA256 and a per-device salt. Returns a
  /// versioned, base64-encoded digest (`v2:...`).
  Future<String> _hashPin(String pin, {String? salt}) async {
    final saltB64 = salt ?? await _ensureDeviceSalt();
    final dk = _pbkdf2(
      utf8.encode(pin),
      base64Decode(saltB64),
      _pbkdf2Iterations,
      32,
    );
    return 'v2:${base64Encode(dk)}';
  }

  /// Reads the per-device salt, creating a cryptographically-random one the
  /// first time.
  Future<String> _ensureDeviceSalt() async {
    final prefs = PreferencesService.instance;
    final existing = prefs.pinSalt;
    if (existing != null && existing.isNotEmpty) return existing;

    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    final saltB64 = base64Encode(bytes);
    await prefs.setPinSalt(saltB64);
    return saltB64;
  }

  /// Standard PBKDF2-HMAC-SHA256.
  List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final prf = Hmac(sha256, password);
    final numBlocks = (keyLength / 32).ceil();
    final derived = <int>[];

    for (var block = 1; block <= numBlocks; block++) {
      final blockIndex = [
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = prf.convert([...salt, ...blockIndex]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = prf.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      derived.addAll(t);
    }
    return derived.sublist(0, keyLength);
  }

  /// Length-constant comparison to avoid leaking via timing.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? AppColors.error
                            : Theme.of(context).colorScheme.primary,
                        width: 2,
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
                child: Text('settings.logout_and_disconnect'.tr()),
              ),
              const SizedBox(height: 8),
            ],
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
            const SizedBox(width: 80), // Empty space
            _NumberButton(
              number: 0,
              onPressed: () => _onNumberPressed(0),
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: IconButton(
                onPressed: _onBackspace,
                icon: const Icon(Icons.backspace_outlined),
                iconSize: 28,
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
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
        ),
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
