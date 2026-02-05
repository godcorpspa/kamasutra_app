import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Stream dello stato utente
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utente corrente
  User? get currentUser => _auth.currentUser;

  // Verifica se loggato
  bool get isLoggedIn => currentUser != null;

  // User ID
  String? get userId => currentUser?.uid;

  // Email utente
  String? get userEmail => currentUser?.email;

  // Nome utente
  String? get displayName => currentUser?.displayName;

  // Registrazione con email
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Registrazione completata: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Errore registrazione: ${e.code}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Login con email
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Login completato: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Errore login: ${e.code}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Login con Google
  Future<UserCredential?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ Login Google annullato');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Login Google completato: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Errore login Google: $e');
      throw Exception('Errore login Google: $e');
    }
  }

  // Login anonimo (per provare senza account)
  Future<UserCredential> loginAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      debugPrint('✅ Login anonimo completato');
      return credential;
    } catch (e) {
      debugPrint('❌ Errore login anonimo: $e');
      throw Exception('Errore login anonimo: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('✅ Logout completato');
    } catch (e) {
      debugPrint('❌ Errore logout: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Email reset password inviata a: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Errore reset password: ${e.code}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Gestione errori
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
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
      default:
        return e.message ?? 'Errore sconosciuto';
    }
  }
}
