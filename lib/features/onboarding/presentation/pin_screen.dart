import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
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
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  String _enteredPin = '';
  String? _firstPin; // For confirmation during creation
  bool _isCreating = false;
  bool _isConfirming = false;
  String? _error;
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _isCreating = PreferencesService.instance.pinHash == null;
  }

  Future<void> _checkBiometric() async {
    if (PreferencesService.instance.isBiometricEnabled) {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canUseBiometric = canCheck && isSupported;
      });
      
      if (_canUseBiometric && !_isCreating) {
        _authenticateWithBiometric();
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'pin.use_biometric'.tr(),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (didAuthenticate && mounted) {
        _onAuthenticationSuccess();
      }
    } catch (e) {
      // Biometric failed, user will need to enter PIN
    }
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
          // Save PIN hash
          final hash = _hashPin(_enteredPin);
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
      final storedHash = PreferencesService.instance.pinHash;
      final enteredHash = _hashPin(_enteredPin);
      
      if (storedHash == enteredHash) {
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

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'kamasutra_salt_2024');
    return sha256.convert(bytes).toString();
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
              
              // Biometric button
              if (_canUseBiometric && !_isCreating)
                TextButton.icon(
                  onPressed: _authenticateWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text('pin.use_biometric'.tr()),
                ),
              
              const Spacer(),
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
