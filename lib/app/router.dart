import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/goose_game.dart';
import '../data/providers/firebase_status_provider.dart';
import '../data/services/auth_service.dart';
import '../data/models/position.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/email_verification_screen.dart';
import '../features/onboarding/presentation/age_gate_screen.dart';
import '../features/onboarding/presentation/pin_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/catalog/presentation/position_detail_screen.dart';
import '../features/shuffle/presentation/shuffle_screen.dart';
import '../features/shuffle/presentation/shuffle_session_screen.dart';
import '../features/games/presentation/games_list_screen.dart';
import '../features/games/goose_game/presentation/goose_play_screen.dart';
import '../features/games/goose_game/presentation/goose_setup_screen.dart';
import '../features/games/truth_dare/presentation/truth_dare_screen.dart';
import '../features/games/wheel/presentation/wheel_screen.dart';
import '../features/games/hot_cold/presentation/hot_cold_screen.dart';
import '../features/games/love_notes/presentation/love_notes_screen.dart';
import '../features/games/fantasy_builder/presentation/fantasy_builder_screen.dart';
import '../features/games/compliment_battle/presentation/compliment_battle_screen.dart';
import '../features/games/question_quest/presentation/question_quest_screen.dart';
import '../features/games/two_minutes/presentation/two_minutes_screen.dart';
import '../features/games/intimacy_map/presentation/intimacy_map_screen.dart';
import '../features/games/soundtrack/presentation/soundtrack_screen.dart';
import '../features/games/mirror_challenge/presentation/mirror_challenge_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../shared/widgets/main_scaffold.dart';
import '../data/services/preferences_service.dart';

/// Route names
class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String emailVerification = '/verify-email';
  
  // Onboarding
  static const String ageGate = '/age-gate';
  static const String pin = '/pin';
  static const String onboarding = '/onboarding';
  
  // Main tabs
  static const String home = '/';
  static const String catalog = '/catalog';
  static const String shuffle = '/shuffle';
  static const String games = '/games';
  static const String progress = '/progress';
  static const String settings = '/settings';
  
  // Detail screens
  static const String positionDetail = '/catalog/:id';
  static const String shuffleSession = '/shuffle/session';
  
  // Games
  static const String gooseGameSetup = '/games/goose/setup';
  static const String gooseGame = '/games/goose/play';
  static const String truthDare = '/games/truth-dare';
  static const String wheel = '/games/wheel';
  static const String hotCold = '/games/hot-cold';
  static const String loveNotes = '/games/love-notes';
  static const String fantasyBuilder = '/games/fantasy-builder';
  static const String complimentBattle = '/games/compliment-battle';
  static const String questionQuest = '/games/question-quest';
  static const String twoMinutes = '/games/two-minutes';
  static const String intimacyMap = '/games/intimacy-map';
  static const String soundtrack = '/games/soundtrack';
  static const String mirrorChallenge = '/games/mirror-challenge';
  
}

/// Shell navigation key for bottom nav (public so MainScaffold can pop modals)
final shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  // Quando Firebase non è disponibile (init fallita in main.dart) l'app gira
  // in modalità SOLO LOCALE: non esiste un login da imporre, quindi l'utente
  // salta la schermata di login ed entra direttamente nel flusso locale
  // (age gate → PIN → onboarding → catalogo).
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    // Redirect logic: un'unica pipeline con le tappe in ordine di priorità
    // (login → verifica email → age gate → PIN → onboarding → app).
    redirect: (context, state) {
      final prefs = PreferencesService.instance;

      final isLoggedIn =
          firebaseAvailable && AuthService.safeCurrentUser != null;
      // Può usare l'app: utente loggato, oppure modalità solo locale.
      final canUseApp = isLoggedIn || !firebaseAvailable;

      final isAgeVerified = prefs.isAgeVerified;
      final hasCompletedOnboarding = prefs.hasCompletedOnboarding;
      final isAuthenticated = prefs.isSessionAuthenticated;
      // Authentication is required if PIN is enabled
      final requiresAuth = prefs.isPinEnabled;

      final location = state.matchedLocation;
      final isOnLogin = location == AppRoutes.login;
      final isOnVerifyEmail = location == AppRoutes.emailVerification;
      final isOnAgeGate = location == AppRoutes.ageGate;
      final isOnOnboarding = location == AppRoutes.onboarding;

      // Gate di verifica email: ci si arriva subito dopo una registrazione
      // fresca. La schermata gestisce da sé tutte le uscite (verificato →
      // avanti, annulla → cancella account e torna al login), quindi il
      // router NON deve mai redirigere altrove chi ci si trova: farlo
      // permetteva ai nuovi account di saltare la verifica (l'age gate
      // scattava prima e portava dritti nell'app).
      if (isOnVerifyEmail) {
        return isLoggedIn ? null : AppRoutes.login;
      }

      // Non loggato (e il login è possibile) -> vai al login.
      if (!canUseApp) {
        return isOnLogin ? null : AppRoutes.login;
      }

      // Da qui in poi l'utente può usare l'app: percorri le tappe in ordine.
      if (!isAgeVerified) {
        return isOnAgeGate ? null : AppRoutes.ageGate;
      }
      if (requiresAuth && !isAuthenticated) {
        return location == AppRoutes.pin ? null : AppRoutes.pin;
      }
      if (!hasCompletedOnboarding) {
        return isOnOnboarding ? null : AppRoutes.onboarding;
      }

      // Onboarding completo: le schermate d'ingresso non sono più valide.
      if (isOnLogin || isOnAgeGate || isOnOnboarding) {
        return AppRoutes.catalog;
      }

      return null;
    },
    
    routes: [
      // Auth route
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),

      // Onboarding routes
      GoRoute(
        path: AppRoutes.ageGate,
        builder: (context, state) => const AgeGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.pin,
        builder: (context, state) => const PinScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.catalog,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CatalogScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => PositionDetailScreen(
                  positionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.shuffle,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ShuffleScreen(),
            ),
            routes: [
              GoRoute(
                path: 'session',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return ShuffleSessionScreen(
                    filter: extra?['filter'] ?? const PositionFilter(),
                    cardCount: extra?['cardCount'] ?? 10,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.games,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GamesListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.progress,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      
      // Game routes (outside shell for full screen)
      GoRoute(
        path: AppRoutes.gooseGameSetup,
        builder: (context, state) => const GooseSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.gooseGame,
        builder: (context, state) {
          final config = state.extra as GooseGameConfig? ?? const GooseGameConfig();
          return GoosePlayScreen(config: config);
        },
      ),
      GoRoute(
        path: AppRoutes.truthDare,
        builder: (context, state) => const TruthDareScreen(),
      ),
      GoRoute(
        path: AppRoutes.wheel,
        builder: (context, state) => const WheelScreen(),
      ),
      GoRoute(
        path: AppRoutes.hotCold,
        builder: (context, state) => const HotColdScreen(),
      ),
      GoRoute(
        path: AppRoutes.loveNotes,
        builder: (context, state) => const LoveNotesScreen(),
      ),
      GoRoute(
        path: AppRoutes.fantasyBuilder,
        builder: (context, state) => const FantasyBuilderScreen(),
      ),
      GoRoute(
        path: AppRoutes.complimentBattle,
        builder: (context, state) => const ComplimentBattleScreen(),
      ),
      GoRoute(
        path: AppRoutes.questionQuest,
        builder: (context, state) => const QuestionQuestScreen(),
      ),
      GoRoute(
        path: AppRoutes.twoMinutes,
        builder: (context, state) => const TwoMinutesScreen(),
      ),
      GoRoute(
        path: AppRoutes.intimacyMap,
        builder: (context, state) => const IntimacyMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.soundtrack,
        builder: (context, state) => const SoundtrackScreen(),
      ),
      GoRoute(
        path: AppRoutes.mirrorChallenge,
        builder: (context, state) => const MirrorChallengeScreen(),
      ),
    ],
  );
});

