import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

/// Provider per AuthService (singleton)
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider per UserRepository (singleton)
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

/// Stream provider per lo stato di autenticazione
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provider per verificare se l'utente è loggato
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider per l'utente corrente
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider per i progressi utente
final userProgressProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  if (!isLoggedIn) return null;
  return ref.watch(userRepositoryProvider).getProgress();
});

/// Stream provider per i preferiti (aggiornamenti real-time)
final favoritesStreamProvider = StreamProvider<List<String>>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  if (!isLoggedIn) return Stream.value([]);
  return ref.watch(userRepositoryProvider).favoritesStream();
});

/// Provider per la lista dei preferiti (one-time fetch)
final favoritesProvider = FutureProvider<List<String>>((ref) async {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  if (!isLoggedIn) return [];
  return ref.watch(userRepositoryProvider).getFavorites();
});
