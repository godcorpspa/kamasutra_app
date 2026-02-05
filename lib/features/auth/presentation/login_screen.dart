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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  bool _isLoading = false;
  bool _isLogin = true; // true = login, false = registrazione
  bool _obscurePassword = true;
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Login
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Registrazione
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      // Naviga alla prossima schermata
      if (mounted) {
        context.go(AppRoutes.ageGate);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova.';
      });
      debugPrint('Errore login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
      // Disconnetti prima per evitare problemi di cache
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // L'utente ha annullato
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      
      if (mounted) {
        context.go(AppRoutes.ageGate);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      // Gestisci l'errore PigeonUserDetails e altri
      final errorStr = e.toString();
      if (errorStr.contains('PigeonUserDetails') || 
          errorStr.contains('subtype')) {
        // L'utente è stato autenticato ma c'è un bug nel plugin
        // Verifica se l'utente è effettivamente loggato
        if (_auth.currentUser != null) {
          if (mounted) {
            context.go(AppRoutes.ageGate);
          }
          return;
        }
      }
      
      setState(() {
        _errorMessage = 'Errore con Google Sign-In. Riprova.';
      });
      debugPrint('Errore Google Sign-In: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'La password è troppo debole (minimo 6 caratteri)';
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
        return 'Errore di autenticazione. Riprova.';
    }
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkBackground,
        title: const Text('Reset Password', style: TextStyle(color: _cream)),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: _cream),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: _cream.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _purple),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _fuchsia),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email di reset inviata! Controlla la tua casella.'),
                      backgroundColor: _purple,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getErrorMessage(e.code)),
                    backgroundColor: Colors.red,
                  ),
                );
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
                const SizedBox(height: 60),
                
                // Logo/Titolo
                Text(
                  '💑',
                  style: const TextStyle(fontSize: 64),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
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
                
                const SizedBox(height: 48),

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
                    prefixIcon: Icon(Icons.email_outlined, color: _fuchsia),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _fuchsia, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci la tua email';
                    }
                    if (!value.contains('@')) {
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
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: _cream.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.lock_outlined, color: _fuchsia),
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
                      borderSide: BorderSide(color: _purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _fuchsia, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci la password';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'La password deve avere almeno 6 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Password dimenticata
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetPasswordDialog,
                      child: Text(
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
                      side: BorderSide(color: _fuchsiaLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

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
                        });
                      },
                      child: Text(
                        _isLogin ? 'Registrati' : 'Accedi',
                        style: TextStyle(
                          color: _fuchsiaLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
