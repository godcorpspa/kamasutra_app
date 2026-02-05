import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/goose_game.dart';
import '../data/models/position.dart';
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
  
  // Panic exit
  static const String panicExit = '/panic';
}

/// Shell navigation key for bottom nav
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.ageGate,
    debugLogDiagnostics: true,
    
    // Redirect logic
    redirect: (context, state) async {
      final prefs = PreferencesService.instance;
      final isAgeVerified = prefs.isAgeVerified;
      final hasCompletedOnboarding = prefs.hasCompletedOnboarding;
      final isPinEnabled = prefs.isPinEnabled;
      final isAuthenticated = prefs.isSessionAuthenticated;
      
      final isOnAgeGate = state.matchedLocation == AppRoutes.ageGate;
      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isOnPin = state.matchedLocation == AppRoutes.pin;
      
      // Not age verified -> age gate
      if (!isAgeVerified && !isOnAgeGate) {
        return AppRoutes.ageGate;
      }
      
      // Age verified but on age gate -> move on
      if (isAgeVerified && isOnAgeGate) {
        if (isPinEnabled && !isAuthenticated) {
          return AppRoutes.pin;
        }
        if (!hasCompletedOnboarding) {
          return AppRoutes.onboarding;
        }
        return AppRoutes.catalog;
      }
      
      // PIN required but not authenticated
      if (isPinEnabled && !isAuthenticated && !isOnPin && !isOnAgeGate) {
        return AppRoutes.pin;
      }
      
      // Onboarding not completed
      if (!hasCompletedOnboarding && !isOnOnboarding && !isOnAgeGate && !isOnPin) {
        return AppRoutes.onboarding;
      }
      
      return null;
    },
    
    routes: [
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
      
      // Panic exit (neutral screen)
      GoRoute(
        path: AppRoutes.panicExit,
        builder: (context, state) => const PanicExitScreen(),
      ),
      
      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
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

/// Panic exit screen - appears as innocent app
class PanicExitScreen extends StatelessWidget {
  const PanicExitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Calculator',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[600],
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
