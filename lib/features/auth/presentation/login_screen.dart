import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../data/services/preferences_service.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/offline_mode_badge.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Getter, non campo: FirebaseAuth.instance lancia in modalità locale
  // (Firebase non inizializzato) e non deve far crashare il build().
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validazione password avanzata
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.enter_password'.tr();
    }
    
    // Per il login, verifica solo che non sia vuota
    if (_isLogin) {
      return null;
    }
    
    // Per la registrazione, validazione completa
    List<String> errors = [];
    
    if (value.length < 8) {
      errors.add('auth.min_8_chars'.tr());
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('auth.one_uppercase'.tr());
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add('auth.one_lowercase'.tr());
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('auth.one_number'.tr());
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]'))) {
      errors.add('auth.one_special'.tr());
    }

    if (errors.isNotEmpty) {
      return 'auth.password_must_contain'.tr(namedArgs: {'errors': errors.join(', ')});
    }
    
    return null;
  }

  // Validazione conferma password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.confirm_password'.tr();
    }

    if (value != _passwordController.text) {
      return 'auth.passwords_dont_match'.tr();
    }
    
    return null;
  }

  // Calcola la forza della password
  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    double strength = 0;
    
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]'))) strength += 0.2;
    
    return strength.clamp(0.0, 1.0);
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength < 0.5) return AppColors.error;
    if (strength < 0.7) return AppColors.jewelAmber;
    return AppColors.jewelSage;
  }

  String _getPasswordStrengthText(double strength) {
    if (strength < 0.3) return 'auth.very_weak'.tr();
    if (strength < 0.5) return 'auth.weak'.tr();
    if (strength < 0.7) return 'auth.medium_strength'.tr();
    if (strength < 0.9) return 'auth.strong'.tr();
    return 'auth.very_strong'.tr();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? errorMsg;
    var registeredFreshAccount = false;

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Send the verification email immediately; the dedicated screen will
        // wait for the user to follow the link before granting app access.
        // Failure here is non-fatal — the user can hit "Resend" on that
        // screen.
        try {
          await _auth.currentUser?.sendEmailVerification();
        } on FirebaseAuthException catch (e) {
          debugPrint('sendEmailVerification failed: ${e.code}');
        }
        registeredFreshAccount = true;
      }
    } on FirebaseAuthException catch (e) {
      errorMsg = _getErrorMessage(e.code);
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Errore generico: $e');
      debugPrint('Tipo errore: ${e.runtimeType}');
    }

    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      debugPrint('✅ Utente autenticato: ${currentUser.email}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (registeredFreshAccount) {
          // New account: gate access on email verification. Existing accounts
          // (sign-in) are routed normally so unverified legacy users are NOT
          // locked out of the app.
          context.go(AppRoutes.emailVerification);
        } else {
          _navigateAfterAuth();
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg ?? 'auth.connection_error'.tr();
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    String? errorCode;

    try {
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException Google: ${e.code}');
      errorCode = e.code;
    } catch (e) {
      debugPrint('Errore Google Sign-In: $e');
      debugPrint('Tipo errore: ${e.runtimeType}');
      errorCode = _googleErrorCode(e);
    }

    final currentUser = _auth.currentUser;
    
    if (currentUser != null) {
      debugPrint('✅ Utente Google autenticato: ${currentUser.email}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _navigateAfterAuth();
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // The technical code is what identifies the cause (e.g. 10 = the
          // app's SHA-1 is not registered in Firebase), so always show it.
          _errorMessage = errorCode == null
              ? 'auth.google_error'.tr()
              : '${'auth.google_error'.tr()} (${'auth.error_code'.tr(namedArgs: {'code': errorCode})})';
        });
      }
    }
  }

  /// Extracts a short, reportable code from a Google Sign-In failure.
  ///
  /// On Android the plugin wraps the Play Services status in the message,
  /// e.g. `ApiException: 10:` — 10 is DEVELOPER_ERROR (SHA-1 / OAuth client
  /// not configured in Firebase), 12500 is SIGN_IN_FAILED, 7 NETWORK_ERROR.
  static String _googleErrorCode(Object error) {
    if (error is PlatformException) {
      final status =
          RegExp(r'ApiException: (\d+)').firstMatch(error.message ?? '');
      return status != null ? '${error.code} ${status.group(1)}' : error.code;
    }
    return error.runtimeType.toString();
  }

  void _navigateAfterAuth() {
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

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'auth.error_weak_password'.tr();
      case 'email-already-in-use':
        return 'auth.error_email_in_use'.tr();
      case 'invalid-email':
        return 'auth.error_invalid_email'.tr();
      case 'user-not-found':
        return 'auth.error_user_not_found'.tr();
      case 'wrong-password':
        return 'auth.error_wrong_password'.tr();
      case 'user-disabled':
        return 'auth.error_user_disabled'.tr();
      case 'too-many-requests':
        return 'auth.error_too_many_requests'.tr();
      case 'invalid-credential':
        return 'auth.error_invalid_credential'.tr();
      case 'operation-not-allowed':
        return 'auth.error_not_allowed'.tr();
      case 'network-request-failed':
        return 'auth.error_network'.tr();
      default:
        return 'auth.error_auth_generic'.tr(namedArgs: {'code': code});
    }
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('auth.reset_password'.tr()),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'auth.email_label'.tr(),
            prefixIcon: const Icon(Icons.mail_outline, size: 20),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: AppColors.mist),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _auth.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('auth.reset_email_sent'.tr())),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_getErrorMessage(e.code))),
                  );
                }
              }
            },
            child: Text('auth.send_btn'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _getPasswordStrength(_passwordController.text);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: VelvetBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 56),
                  const BrandLockup(markSize: 44),
                  const SizedBox(height: 44),
                  Text(
                    _isLogin
                        ? 'auth.welcome_back'.tr()
                        : 'auth.create_account'.tr(),
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Offline indicator — visible only when Firebase is
                  // unavailable (login can't work without it).
                  const OfflineModeBadge(),

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

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'auth.email_label'.tr(),
                      prefixIcon: const Icon(Icons.mail_outline, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'auth.enter_email'.tr();
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'auth.invalid_email'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    onChanged: (value) {
                      // Aggiorna l'indicatore di forza password
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'auth.password_label'.tr(),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      errorMaxLines: 3,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                  ),

                  // Indicatore forza password (solo in registrazione)
                  if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: passwordStrength,
                              minHeight: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getPasswordStrengthColor(passwordStrength),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getPasswordStrengthText(passwordStrength),
                          style: TextStyle(
                            color: _getPasswordStrengthColor(passwordStrength),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordRequirements(),
                  ],

                  const SizedBox(height: 14),

                  // Conferma Password (solo in registrazione)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'auth.confirm_password'.tr(),
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Password dimenticata (solo in login)
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showResetPasswordDialog,
                        child: Text('auth.forgot_password'.tr()),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Pulsante principale
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.champagne,
                              ),
                            )
                          : Text(_isLogin
                              ? 'auth.login'.tr()
                              : 'auth.register'.tr()),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'auth.or_divider'.tr().toUpperCase(),
                          style: AppTypography.eyebrow,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Google Sign In
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        height: 20,
                        width: 20,
                        errorBuilder: (_, __, ___) => const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ivory,
                          ),
                        ),
                      ),
                      label: Text('auth.continue_google'.tr()),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Switch login/registrazione
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? 'auth.no_account'.tr()
                            : 'auth.has_account'.tr(),
                        style: const TextStyle(color: AppColors.mist),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                            _confirmPasswordController.clear();
                          });
                        },
                        child: Text(
                          _isLogin ? 'auth.register'.tr() : 'auth.login'.tr(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget per mostrare i requisiti della password
  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirementRow(
            'auth.req_min_chars'.tr(),
            password.length >= 8,
          ),
          _buildRequirementRow(
            'auth.req_uppercase'.tr(),
            password.contains(RegExp(r'[A-Z]')),
          ),
          _buildRequirementRow(
            'auth.req_lowercase'.tr(),
            password.contains(RegExp(r'[a-z]')),
          ),
          _buildRequirementRow(
            'auth.req_number'.tr(),
            password.contains(RegExp(r'[0-9]')),
          ),
          _buildRequirementRow(
            'auth.req_special'.tr(),
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]')),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    final color = isMet ? AppColors.jewelSage : AppColors.smoke;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 11.5, color: color)),
        ],
      ),
    );
  }
}
