import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/router.dart';
import '../../../data/services/preferences_service.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Colori tema
  static const Color _darkBackground = Color(0xFF1A0A1F);
  static const Color _purple = Color(0xFF6B2D5B);
  static const Color _fuchsia = Color(0xFFD946EF);
  static const Color _fuchsiaLight = Color(0xFFE879F9);
  static const Color _cream = Color(0xFFFFF8F0);

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
      return 'Inserisci la password';
    }
    
    // Per il login, verifica solo che non sia vuota
    if (_isLogin) {
      return null;
    }
    
    // Per la registrazione, validazione completa
    List<String> errors = [];
    
    if (value.length < 8) {
      errors.add('almeno 8 caratteri');
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('una lettera maiuscola');
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add('una lettera minuscola');
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('un numero');
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]'))) {
      errors.add('un carattere speciale (!@#\$%^&*...)');
    }
    
    if (errors.isNotEmpty) {
      return 'La password deve contenere: ${errors.join(', ')}';
    }
    
    return null;
  }

  // Validazione conferma password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Conferma la password';
    }
    
    if (value != _passwordController.text) {
      return 'Le password non corrispondono';
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
    if (strength < 0.3) return Colors.red;
    if (strength < 0.5) return Colors.orange;
    if (strength < 0.7) return Colors.yellow;
    if (strength < 0.9) return Colors.lightGreen;
    return Colors.green;
  }

  String _getPasswordStrengthText(double strength) {
    if (strength < 0.3) return 'Molto debole';
    if (strength < 0.5) return 'Debole';
    if (strength < 0.7) return 'Media';
    if (strength < 0.9) return 'Forte';
    return 'Molto forte';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? errorMsg;

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
        _navigateAfterAuth();
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg ?? 'Errore di connessione. Riprova.';
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
    } catch (e) {
      debugPrint('Errore Google Sign-In: $e');
      debugPrint('Tipo errore: ${e.runtimeType}');
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
          _errorMessage = 'Errore con Google Sign-In. Riprova.';
        });
      }
    }
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
        return 'La password è troppo debole';
      case 'email-already-in-use':
        return 'Questa email è già registrata';
      case 'invalid-email':
        return 'Email non valida';
      case 'user-not-found':
        return 'Nessun account trovato con questa email';
      case 'wrong-password':
        return 'Password errata';
      case 'user-disabled':
        return 'Account disabilitato';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova tra qualche minuto';
      case 'invalid-credential':
        return 'Email o password non corretti';
      case 'operation-not-allowed':
        return 'Operazione non consentita';
      case 'network-request-failed':
        return 'Errore di rete. Controlla la connessione.';
      default:
        return 'Errore di autenticazione ($code)';
    }
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _darkBackground,
        title: const Text('Reset Password', style: TextStyle(color: _cream)),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: _cream),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: _cream.withOpacity(0.7)),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: _purple),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: _fuchsia),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annulla', style: TextStyle(color: _cream.withOpacity(0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            onPressed: () async {
              try {
                await _auth.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email di reset inviata! Controlla la tua casella.'),
                      backgroundColor: _purple,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getErrorMessage(e.code)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Invia'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _getPasswordStrength(_passwordController.text);
    
    return Scaffold(
      backgroundColor: _darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo/Titolo
                const Text(
                  '💑',
                  style: TextStyle(fontSize: 64),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kamasutra App',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _fuchsiaLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Bentornato!' : 'Crea il tuo account',
                  style: TextStyle(
                    fontSize: 16,
                    color: _cream.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),

                // Messaggio errore
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: _cream),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: _cream.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.email_outlined, color: _fuchsia),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _fuchsia, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci la tua email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email non valida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: _cream),
                  onChanged: (value) {
                    // Aggiorna l'indicatore di forza password
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: _cream.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.lock_outlined, color: _fuchsia),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: _fuchsia.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _fuchsia, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                    errorMaxLines: 3,
                  ),
                  validator: _validatePassword,
                ),
                
                // Indicatore forza password (solo in registrazione)
                if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: passwordStrength,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getPasswordStrengthColor(passwordStrength),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getPasswordStrengthText(passwordStrength),
                        style: TextStyle(
                          color: _getPasswordStrengthColor(passwordStrength),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Requisiti password
                  _buildPasswordRequirements(),
                ],
                
                const SizedBox(height: 16),

                // Conferma Password (solo in registrazione)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: _cream),
                    decoration: InputDecoration(
                      labelText: 'Conferma Password',
                      labelStyle: TextStyle(color: _cream.withOpacity(0.7)),
                      prefixIcon: const Icon(Icons.lock_outline, color: _fuchsia),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: _fuchsia.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _purple),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _fuchsia, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      errorStyle: const TextStyle(color: Colors.red),
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
                      child: const Text(
                        'Password dimenticata?',
                        style: TextStyle(color: _fuchsiaLight),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Pulsante principale
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: _cream,
                      disabledBackgroundColor: _purple.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _cream,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Accedi' : 'Registrati',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: _cream.withOpacity(0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'oppure',
                        style: TextStyle(color: _cream.withOpacity(0.5)),
                      ),
                    ),
                    Expanded(child: Divider(color: _cream.withOpacity(0.2))),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 24,
                      width: 24,
                      errorBuilder: (_, __, ___) => const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    label: const Text('Continua con Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: const BorderSide(color: _fuchsiaLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Switch login/registrazione
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Non hai un account?' : 'Hai già un account?',
                      style: TextStyle(color: _cream.withOpacity(0.7)),
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
                        _isLogin ? 'Registrati' : 'Accedi',
                        style: const TextStyle(
                          color: _fuchsiaLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
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
            'Minimo 8 caratteri',
            password.length >= 8,
          ),
          _buildRequirementRow(
            'Una lettera maiuscola (A-Z)',
            password.contains(RegExp(r'[A-Z]')),
          ),
          _buildRequirementRow(
            'Una lettera minuscola (a-z)',
            password.contains(RegExp(r'[a-z]')),
          ),
          _buildRequirementRow(
            'Un numero (0-9)',
            password.contains(RegExp(r'[0-9]')),
          ),
          _buildRequirementRow(
            'Un carattere speciale (!@#\$%...)',
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]')),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : _cream.withOpacity(0.4),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? Colors.green : _cream.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}