import 'package:equatable/equatable.dart';
import 'game.dart';

/// Goose Game board sizes
enum GooseBoardSize {
  quick,   // 30 squares, 15-20 min
  medium,  // 50 squares, 30-40 min
  long,    // 100 squares, 60+ min
}

extension GooseBoardSizeExtension on GooseBoardSize {
  int get totalSquares {
    switch (this) {
      case GooseBoardSize.quick:
        return 30;
      case GooseBoardSize.medium:
        return 50;
      case GooseBoardSize.long:
        return 100;
    }
  }

  String getDisplayName(String locale) {
    switch (this) {
      case GooseBoardSize.quick:
        return locale == 'it' ? 'Veloce (15-20 min)' : 'Quick (15-20 min)';
      case GooseBoardSize.medium:
        return locale == 'it' ? 'Medio (30-40 min)' : 'Medium (30-40 min)';
      case GooseBoardSize.long:
        return locale == 'it' ? 'Lungo (60+ min)' : 'Long (60+ min)';
    }
  }
}

/// Goose Game play modes
enum GoosePlayMode {
  cooperative,    // Shared progress
  sweetChallenge, // Two pawns, both win
}

extension GoosePlayModeExtension on GoosePlayMode {
  String getDisplayName(String locale) {
    switch (this) {
      case GoosePlayMode.cooperative:
        return locale == 'it' ? 'Cooperativo' : 'Cooperative';
      case GoosePlayMode.sweetChallenge:
        return locale == 'it' ? 'Dolce Sfida' : 'Sweet Challenge';
    }
  }

  String getDescription(String locale) {
    switch (this) {
      case GoosePlayMode.cooperative:
        return locale == 'it' 
            ? 'Avanzate insieme, un solo pedone'
            : 'Advance together, one pawn';
      case GoosePlayMode.sweetChallenge:
        return locale == 'it'
            ? 'Due pedine, entrambi vincete'
            : 'Two pawns, both win';
    }
  }
}

/// Square types on the board
enum GooseSquareType {
  normal,      // Regular square
  challenge,   // 🎯 Draw challenge card
  truth,       // 💬 Draw truth/confession card
  bonus,       // ⭐ Advance 1-3 extra squares
  goose,       // 🪿 Roll again
  bridge,      // 🌉 Jump to next bridge
  well,        // 🕳️ Skip turn (escape with compliment)
  labyrinth,   // 🌀 Go back 5 squares
  inn,         // 🏨 Romantic pause, choose position
  couple,      // 💑 Special couple mini-challenge
  finish,      // 🏁 Must roll exact
}

extension GooseSquareTypeExtension on GooseSquareType {
  String get emoji {
    switch (this) {
      case GooseSquareType.normal:
        return '';
      case GooseSquareType.challenge:
        return '🎯';
      case GooseSquareType.truth:
        return '💬';
      case GooseSquareType.bonus:
        return '⭐';
      case GooseSquareType.goose:
        return '🪿';
      case GooseSquareType.bridge:
        return '🌉';
      case GooseSquareType.well:
        return '🕳️';
      case GooseSquareType.labyrinth:
        return '🌀';
      case GooseSquareType.inn:
        return '🏨';
      case GooseSquareType.couple:
        return '💑';
      case GooseSquareType.finish:
        return '🏁';
    }
  }

  String getName(String locale) {
    switch (this) {
      case GooseSquareType.normal:
        return locale == 'it' ? 'Normale' : 'Normal';
      case GooseSquareType.challenge:
        return locale == 'it' ? 'Sfida' : 'Challenge';
      case GooseSquareType.truth:
        return locale == 'it' ? 'Verità' : 'Truth';
      case GooseSquareType.bonus:
        return locale == 'it' ? 'Bonus' : 'Bonus';
      case GooseSquareType.goose:
        return locale == 'it' ? 'Oca' : 'Goose';
      case GooseSquareType.bridge:
        return locale == 'it' ? 'Ponte' : 'Bridge';
      case GooseSquareType.well:
        return locale == 'it' ? 'Pozzo' : 'Well';
      case GooseSquareType.labyrinth:
        return locale == 'it' ? 'Labirinto' : 'Labyrinth';
      case GooseSquareType.inn:
        return locale == 'it' ? 'Locanda' : 'Inn';
      case GooseSquareType.couple:
        return locale == 'it' ? 'Coppia' : 'Couple';
      case GooseSquareType.finish:
        return locale == 'it' ? 'Arrivo' : 'Finish';
    }
  }
}

/// A square on the board
class GooseSquare extends Equatable {
  final int position;
  final GooseSquareType type;

  const GooseSquare({
    required this.position,
    required this.type,
  });

  @override
  List<Object?> get props => [position, type];
}

/// Card for challenges and truths
class GooseCard extends Equatable {
  final String id;
  final String textIt;
  final String textEn;
  final GameIntensity intensity;
  final bool isChallenge; // true = challenge, false = truth

  const GooseCard({
    required this.id,
    required this.textIt,
    required this.textEn,
    required this.intensity,
    required this.isChallenge,
  });

  String getText(String locale) => locale == 'it' ? textIt : textEn;
  
  /// Convenience getter for localized text (defaults to English)
  String get localizedText => textEn;

  @override
  List<Object?> get props => [id, textIt, textEn, intensity, isChallenge];
}

/// Goose game configuration
class GooseGameConfig extends Equatable {
  final GooseBoardSize boardSize;
  final GoosePlayMode playMode;
  final GameIntensity intensity;
  final bool useRiggedDice; // 3-5 instead of 1-6 for smoother flow
  final List<GooseSquareType> excludedSquareTypes;

  const GooseGameConfig({
    this.boardSize = GooseBoardSize.medium,
    this.playMode = GoosePlayMode.cooperative,
    this.intensity = GameIntensity.soft,
    this.useRiggedDice = true,
    this.excludedSquareTypes = const [],
  });

  GooseGameConfig copyWith({
    GooseBoardSize? boardSize,
    GoosePlayMode? playMode,
    GameIntensity? intensity,
    bool? useRiggedDice,
    List<GooseSquareType>? excludedSquareTypes,
  }) {
    return GooseGameConfig(
      boardSize: boardSize ?? this.boardSize,
      playMode: playMode ?? this.playMode,
      intensity: intensity ?? this.intensity,
      useRiggedDice: useRiggedDice ?? this.useRiggedDice,
      excludedSquareTypes: excludedSquareTypes ?? this.excludedSquareTypes,
    );
  }

  @override
  List<Object?> get props => [
    boardSize, playMode, intensity, useRiggedDice, excludedSquareTypes,
  ];
}

/// Current state of a goose game in progress
class GooseGameState extends Equatable {
  final GooseGameConfig config;
  final List<GooseSquare> board;
  final int player1Position;
  final int player2Position; // Only used in sweetChallenge mode
  final int currentPlayer; // 1 or 2
  final bool player1InWell;
  final bool player2InWell;
  final int lastDiceRoll;
  final GooseCard? currentCard;
  final bool gameCompleted;
  final DateTime startedAt;

  const GooseGameState({
    required this.config,
    required this.board,
    this.player1Position = 0,
    this.player2Position = 0,
    this.currentPlayer = 1,
    this.player1InWell = false,
    this.player2InWell = false,
    this.lastDiceRoll = 0,
    this.currentCard,
    this.gameCompleted = false,
    required this.startedAt,
  });

  /// Get current position based on play mode
  int get currentPosition {
    if (config.playMode == GoosePlayMode.cooperative) {
      return player1Position;
    }
    return currentPlayer == 1 ? player1Position : player2Position;
  }

  /// Check if current player is in well
  bool get currentPlayerInWell {
    if (config.playMode == GoosePlayMode.cooperative) {
      return player1InWell;
    }
    return currentPlayer == 1 ? player1InWell : player2InWell;
  }

  /// Progress percentage
  double get progressPercentage {
    final totalSquares = config.boardSize.totalSquares;
    if (config.playMode == GoosePlayMode.cooperative) {
      return player1Position / totalSquares;
    }
    // For sweet challenge, average of both players
    return (player1Position + player2Position) / (2 * totalSquares);
  }

  /// Check if at checkpoint (every 25 squares)
  bool isAtCheckpoint(int position) {
    return position > 0 && position % 25 == 0;
  }

  GooseGameState copyWith({
    GooseGameConfig? config,
    List<GooseSquare>? board,
    int? player1Position,
    int? player2Position,
    int? currentPlayer,
    bool? player1InWell,
    bool? player2InWell,
    int? lastDiceRoll,
    GooseCard? currentCard,
    bool? gameCompleted,
    DateTime? startedAt,
  }) {
    return GooseGameState(
      config: config ?? this.config,
      board: board ?? this.board,
      player1Position: player1Position ?? this.player1Position,
      player2Position: player2Position ?? this.player2Position,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      player1InWell: player1InWell ?? this.player1InWell,
      player2InWell: player2InWell ?? this.player2InWell,
      lastDiceRoll: lastDiceRoll ?? this.lastDiceRoll,
      currentCard: currentCard ?? this.currentCard,
      gameCompleted: gameCompleted ?? this.gameCompleted,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => [
    config, board, player1Position, player2Position, currentPlayer,
    player1InWell, player2InWell, lastDiceRoll, currentCard,
    gameCompleted, startedAt,
  ];
}
