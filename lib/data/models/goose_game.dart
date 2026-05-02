import 'package:equatable/equatable.dart';

// ==================== SQUARE TYPES ====================

enum GooseSquareType {
  normal,   // Casella normale
  ladder,   // 🪜 Scala: avanza + ricompensa dal partner
  hole,     // 🕳️ Buco: torna indietro + penitenza
  penance,  // 🔥 Penitenza hot
  finish,   // 🏆 Arrivo
}

extension GooseSquareTypeExtension on GooseSquareType {
  String get emoji {
    switch (this) {
      case GooseSquareType.normal:  return '';
      case GooseSquareType.ladder:  return '🪜';
      case GooseSquareType.hole:    return '🕳️';
      case GooseSquareType.penance: return '🔥';
      case GooseSquareType.finish:  return '🏆';
    }
  }

  String get nameIt {
    switch (this) {
      case GooseSquareType.normal:  return 'Normale';
      case GooseSquareType.ladder:  return 'Scala';
      case GooseSquareType.hole:    return 'Buco';
      case GooseSquareType.penance: return 'Penitenza';
      case GooseSquareType.finish:  return 'Arrivo';
    }
  }
}

// ==================== BOARD SQUARE ====================

class GooseSquare extends Equatable {
  final int position;
  final GooseSquareType type;
  final int? destination; // For ladder/hole: where to jump

  const GooseSquare({
    required this.position,
    required this.type,
    this.destination,
  });

  @override
  List<Object?> get props => [position, type, destination];
}

// ==================== CONTENT (reward / penance) ====================

class GooseContent {
  final String text;
  final int? timerSeconds; // null = not timed

  const GooseContent(this.text, {this.timerSeconds});
}

// ==================== GENDER ====================

enum PlayerGender { male, female }

// ==================== GAME CONFIG ====================

class GooseGameConfig extends Equatable {
  final String player1Name;
  final String player2Name;
  final PlayerGender player1Gender;
  final PlayerGender player2Gender;

  const GooseGameConfig({
    this.player1Name = 'Giocatore 1',
    this.player2Name = 'Giocatore 2',
    this.player1Gender = PlayerGender.male,
    this.player2Gender = PlayerGender.female,
  });

  GooseGameConfig copyWith({
    String? player1Name,
    String? player2Name,
    PlayerGender? player1Gender,
    PlayerGender? player2Gender,
  }) {
    return GooseGameConfig(
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      player1Gender: player1Gender ?? this.player1Gender,
      player2Gender: player2Gender ?? this.player2Gender,
    );
  }

  @override
  List<Object?> get props => [player1Name, player2Name, player1Gender, player2Gender];
}

// ==================== BOARD CONSTANTS ====================

/// Ladders: key = from, value = to (jump always +8..+12)
const Map<int, int> kLadderMap = {
   6: 16,   // +10
  13: 21,   // +8
  26: 36,   // +10
  40: 50,   // +10
  53: 63,   // +10
  66: 76,   // +10
  78: 88,   // +10
  85: 95,   // +10
};

/// Holes: key = from, value = to (jump always -8..-10)
/// Extra holes added in the 10-49 range.
const Map<int, int> kHoleMap = {
  18: 9,    // -9  [10-49 zone]
  29: 19,   // -10 [10-49 zone]
  37: 27,   // -10 [10-49 zone]
  44: 34,   // -10 [10-49 zone]
  57: 48,   // -9
  71: 61,   // -10
  83: 73,   // -10
  96: 86,   // -10
};

/// Penance squares (scattered)
const Set<int> kPenanceSquares = {3, 8, 15, 22, 30, 35, 42, 47, 55, 68, 75, 82, 90};

// ==================== REWARDS (124) ====================
//
// Each entry stores a translation key (games.goose_game.reward_NNN).
// Call .tr() on `content.text` at display time to get the localized string.

const List<GooseContent> kRewards = [
  GooseContent('games.goose_game.reward_001', timerSeconds: 180),
  GooseContent('games.goose_game.reward_002', timerSeconds: 120),
  GooseContent('games.goose_game.reward_003', timerSeconds: 180),
  GooseContent('games.goose_game.reward_004', timerSeconds: 180),
  GooseContent('games.goose_game.reward_005', timerSeconds: 120),
  GooseContent('games.goose_game.reward_006', timerSeconds: 120),
  GooseContent('games.goose_game.reward_007', timerSeconds: 180),
  GooseContent('games.goose_game.reward_008', timerSeconds: 120),
  GooseContent('games.goose_game.reward_009', timerSeconds: 120),
  GooseContent('games.goose_game.reward_010', timerSeconds: 30),
  GooseContent('games.goose_game.reward_011', timerSeconds: 120),
  GooseContent('games.goose_game.reward_012', timerSeconds: 300),
  GooseContent('games.goose_game.reward_013', timerSeconds: 60),
  GooseContent('games.goose_game.reward_014', timerSeconds: 60),
  GooseContent('games.goose_game.reward_015'),
  GooseContent('games.goose_game.reward_016', timerSeconds: 30),
  GooseContent('games.goose_game.reward_017'),
  GooseContent('games.goose_game.reward_018', timerSeconds: 30),
  GooseContent('games.goose_game.reward_019', timerSeconds: 30),
  GooseContent('games.goose_game.reward_020'),
  GooseContent('games.goose_game.reward_021'),
  GooseContent('games.goose_game.reward_022', timerSeconds: 45),
  GooseContent('games.goose_game.reward_023'),
  GooseContent('games.goose_game.reward_024', timerSeconds: 30),
  GooseContent('games.goose_game.reward_025'),
  GooseContent('games.goose_game.reward_026'),
  GooseContent('games.goose_game.reward_027'),
  GooseContent('games.goose_game.reward_028'),
  GooseContent('games.goose_game.reward_029', timerSeconds: 30),
  GooseContent('games.goose_game.reward_030'),
  GooseContent('games.goose_game.reward_031'),
  GooseContent('games.goose_game.reward_032', timerSeconds: 45),
  GooseContent('games.goose_game.reward_033', timerSeconds: 30),
  GooseContent('games.goose_game.reward_034', timerSeconds: 30),
  GooseContent('games.goose_game.reward_035'),
  GooseContent('games.goose_game.reward_036', timerSeconds: 60),
  GooseContent('games.goose_game.reward_037', timerSeconds: 120),
  GooseContent('games.goose_game.reward_038', timerSeconds: 45),
  GooseContent('games.goose_game.reward_039'),
  GooseContent('games.goose_game.reward_040', timerSeconds: 60),
  GooseContent('games.goose_game.reward_041', timerSeconds: 60),
  GooseContent('games.goose_game.reward_042', timerSeconds: 120),
  GooseContent('games.goose_game.reward_043', timerSeconds: 30),
  GooseContent('games.goose_game.reward_044', timerSeconds: 60),
  GooseContent('games.goose_game.reward_045', timerSeconds: 30),
  GooseContent('games.goose_game.reward_046', timerSeconds: 90),
  GooseContent('games.goose_game.reward_047', timerSeconds: 60),
  GooseContent('games.goose_game.reward_048', timerSeconds: 60),
  GooseContent('games.goose_game.reward_049'),
  GooseContent('games.goose_game.reward_050', timerSeconds: 60),
  GooseContent('games.goose_game.reward_051'),
  GooseContent('games.goose_game.reward_052', timerSeconds: 60),
  GooseContent('games.goose_game.reward_053', timerSeconds: 30),
  GooseContent('games.goose_game.reward_054', timerSeconds: 30),
  GooseContent('games.goose_game.reward_055', timerSeconds: 60),
  GooseContent('games.goose_game.reward_056'),
  GooseContent('games.goose_game.reward_057', timerSeconds: 120),
  GooseContent('games.goose_game.reward_058', timerSeconds: 60),
  GooseContent('games.goose_game.reward_059'),
  GooseContent('games.goose_game.reward_060', timerSeconds: 60),
  GooseContent('games.goose_game.reward_061', timerSeconds: 120),
  GooseContent('games.goose_game.reward_062', timerSeconds: 60),
  GooseContent('games.goose_game.reward_063'),
  GooseContent('games.goose_game.reward_064'),
  GooseContent('games.goose_game.reward_065'),
  GooseContent('games.goose_game.reward_066'),
  GooseContent('games.goose_game.reward_067'),
  GooseContent('games.goose_game.reward_068'),
  GooseContent('games.goose_game.reward_069'),
  GooseContent('games.goose_game.reward_070'),
  GooseContent('games.goose_game.reward_071'),
  GooseContent('games.goose_game.reward_072'),
  GooseContent('games.goose_game.reward_073'),
  GooseContent('games.goose_game.reward_074'),
  GooseContent('games.goose_game.reward_075'),
  GooseContent('games.goose_game.reward_076'),
  GooseContent('games.goose_game.reward_077'),
  GooseContent('games.goose_game.reward_078'),
  GooseContent('games.goose_game.reward_079'),
  GooseContent('games.goose_game.reward_080'),
  GooseContent('games.goose_game.reward_081'),
  GooseContent('games.goose_game.reward_082'),
  GooseContent('games.goose_game.reward_083', timerSeconds: 30),
  GooseContent('games.goose_game.reward_084'),
  GooseContent('games.goose_game.reward_085'),
  GooseContent('games.goose_game.reward_086'),
  GooseContent('games.goose_game.reward_087'),
  GooseContent('games.goose_game.reward_088'),
  GooseContent('games.goose_game.reward_089'),
  GooseContent('games.goose_game.reward_090', timerSeconds: 120),
  GooseContent('games.goose_game.reward_091', timerSeconds: 180),
  GooseContent('games.goose_game.reward_092'),
  GooseContent('games.goose_game.reward_093', timerSeconds: 300),
  GooseContent('games.goose_game.reward_094'),
  GooseContent('games.goose_game.reward_095'),
  GooseContent('games.goose_game.reward_096', timerSeconds: 120),
  GooseContent('games.goose_game.reward_097'),
  GooseContent('games.goose_game.reward_098', timerSeconds: 30),
  GooseContent('games.goose_game.reward_099', timerSeconds: 60),
  GooseContent('games.goose_game.reward_100'),
  GooseContent('games.goose_game.reward_101'),
  GooseContent('games.goose_game.reward_102', timerSeconds: 60),
  GooseContent('games.goose_game.reward_103'),
  GooseContent('games.goose_game.reward_104', timerSeconds: 60),
  GooseContent('games.goose_game.reward_105', timerSeconds: 120),
  GooseContent('games.goose_game.reward_106'),
  GooseContent('games.goose_game.reward_107', timerSeconds: 60),
  GooseContent('games.goose_game.reward_108', timerSeconds: 300),
  GooseContent('games.goose_game.reward_109', timerSeconds: 300),
  GooseContent('games.goose_game.reward_110', timerSeconds: 60),
  GooseContent('games.goose_game.reward_111'),
  GooseContent('games.goose_game.reward_112'),
  GooseContent('games.goose_game.reward_113'),
  GooseContent('games.goose_game.reward_114'),
  GooseContent('games.goose_game.reward_115'),
  GooseContent('games.goose_game.reward_116'),
  GooseContent('games.goose_game.reward_117'),
  GooseContent('games.goose_game.reward_118', timerSeconds: 180),
  GooseContent('games.goose_game.reward_119', timerSeconds: 60),
  GooseContent('games.goose_game.reward_120', timerSeconds: 90),
  GooseContent('games.goose_game.reward_121', timerSeconds: 120),
  GooseContent('games.goose_game.reward_122', timerSeconds: 30),
  GooseContent('games.goose_game.reward_123', timerSeconds: 180),
  GooseContent('games.goose_game.reward_124'),
];

// ==================== PENANCES (116) ====================
//
// Each entry stores a translation key (games.goose_game.penance_NNN).
// Call .tr() on `content.text` at display time to get the localized string.

const List<GooseContent> kPenances = [
  GooseContent('games.goose_game.penance_001', timerSeconds: 180),
  GooseContent('games.goose_game.penance_002', timerSeconds: 120),
  GooseContent('games.goose_game.penance_003', timerSeconds: 180),
  GooseContent('games.goose_game.penance_004', timerSeconds: 120),
  GooseContent('games.goose_game.penance_005', timerSeconds: 120),
  GooseContent('games.goose_game.penance_006', timerSeconds: 30),
  GooseContent('games.goose_game.penance_007', timerSeconds: 120),
  GooseContent('games.goose_game.penance_008', timerSeconds: 300),
  GooseContent('games.goose_game.penance_009', timerSeconds: 120),
  GooseContent('games.goose_game.penance_010', timerSeconds: 30),
  GooseContent('games.goose_game.penance_011'),
  GooseContent('games.goose_game.penance_012', timerSeconds: 30),
  GooseContent('games.goose_game.penance_013', timerSeconds: 20),
  GooseContent('games.goose_game.penance_014', timerSeconds: 20),
  GooseContent('games.goose_game.penance_015'),
  GooseContent('games.goose_game.penance_016', timerSeconds: 45),
  GooseContent('games.goose_game.penance_017'),
  GooseContent('games.goose_game.penance_018'),
  GooseContent('games.goose_game.penance_019'),
  GooseContent('games.goose_game.penance_020'),
  GooseContent('games.goose_game.penance_021'),
  GooseContent('games.goose_game.penance_022'),
  GooseContent('games.goose_game.penance_023', timerSeconds: 30),
  GooseContent('games.goose_game.penance_024', timerSeconds: 30),
  GooseContent('games.goose_game.penance_025'),
  GooseContent('games.goose_game.penance_026', timerSeconds: 30),
  GooseContent('games.goose_game.penance_027', timerSeconds: 60),
  GooseContent('games.goose_game.penance_028', timerSeconds: 120),
  GooseContent('games.goose_game.penance_029', timerSeconds: 45),
  GooseContent('games.goose_game.penance_030', timerSeconds: 60),
  GooseContent('games.goose_game.penance_031', timerSeconds: 60),
  GooseContent('games.goose_game.penance_032', timerSeconds: 120),
  GooseContent('games.goose_game.penance_033', timerSeconds: 30),
  GooseContent('games.goose_game.penance_034', timerSeconds: 60),
  GooseContent('games.goose_game.penance_035', timerSeconds: 30),
  GooseContent('games.goose_game.penance_036', timerSeconds: 90),
  GooseContent('games.goose_game.penance_037', timerSeconds: 60),
  GooseContent('games.goose_game.penance_038', timerSeconds: 60),
  GooseContent('games.goose_game.penance_039'),
  GooseContent('games.goose_game.penance_040', timerSeconds: 180),
  GooseContent('games.goose_game.penance_041'),
  GooseContent('games.goose_game.penance_042', timerSeconds: 30),
  GooseContent('games.goose_game.penance_043', timerSeconds: 30),
  GooseContent('games.goose_game.penance_044', timerSeconds: 30),
  GooseContent('games.goose_game.penance_045', timerSeconds: 60),
  GooseContent('games.goose_game.penance_046'),
  GooseContent('games.goose_game.penance_047', timerSeconds: 120),
  GooseContent('games.goose_game.penance_048', timerSeconds: 60),
  GooseContent('games.goose_game.penance_049'),
  GooseContent('games.goose_game.penance_050', timerSeconds: 60),
  GooseContent('games.goose_game.penance_051', timerSeconds: 120),
  GooseContent('games.goose_game.penance_052', timerSeconds: 60),
  GooseContent('games.goose_game.penance_053', timerSeconds: 90),
  GooseContent('games.goose_game.penance_054'),
  GooseContent('games.goose_game.penance_055'),
  GooseContent('games.goose_game.penance_056', timerSeconds: 60),
  GooseContent('games.goose_game.penance_057'),
  GooseContent('games.goose_game.penance_058'),
  GooseContent('games.goose_game.penance_059'),
  GooseContent('games.goose_game.penance_060'),
  GooseContent('games.goose_game.penance_061'),
  GooseContent('games.goose_game.penance_062'),
  GooseContent('games.goose_game.penance_063'),
  GooseContent('games.goose_game.penance_064'),
  GooseContent('games.goose_game.penance_065'),
  GooseContent('games.goose_game.penance_066'),
  GooseContent('games.goose_game.penance_067'),
  GooseContent('games.goose_game.penance_068'),
  GooseContent('games.goose_game.penance_069'),
  GooseContent('games.goose_game.penance_070'),
  GooseContent('games.goose_game.penance_071'),
  GooseContent('games.goose_game.penance_072'),
  GooseContent('games.goose_game.penance_073'),
  GooseContent('games.goose_game.penance_074'),
  GooseContent('games.goose_game.penance_075'),
  GooseContent('games.goose_game.penance_076'),
  GooseContent('games.goose_game.penance_077'),
  GooseContent('games.goose_game.penance_078'),
  GooseContent('games.goose_game.penance_079'),
  GooseContent('games.goose_game.penance_080'),
  GooseContent('games.goose_game.penance_081'),
  GooseContent('games.goose_game.penance_082'),
  GooseContent('games.goose_game.penance_083'),
  GooseContent('games.goose_game.penance_084'),
  GooseContent('games.goose_game.penance_085'),
  GooseContent('games.goose_game.penance_086'),
  GooseContent('games.goose_game.penance_087'),
  GooseContent('games.goose_game.penance_088'),
  GooseContent('games.goose_game.penance_089', timerSeconds: 30),
  GooseContent('games.goose_game.penance_090', timerSeconds: 30),
  GooseContent('games.goose_game.penance_091', timerSeconds: 120),
  GooseContent('games.goose_game.penance_092', timerSeconds: 180),
  GooseContent('games.goose_game.penance_093', timerSeconds: 60),
  GooseContent('games.goose_game.penance_094'),
  GooseContent('games.goose_game.penance_095'),
  GooseContent('games.goose_game.penance_096', timerSeconds: 120),
  GooseContent('games.goose_game.penance_097'),
  GooseContent('games.goose_game.penance_098'),
  GooseContent('games.goose_game.penance_099'),
  GooseContent('games.goose_game.penance_100'),
  GooseContent('games.goose_game.penance_101'),
  GooseContent('games.goose_game.penance_102'),
  GooseContent('games.goose_game.penance_103', timerSeconds: 60),
  GooseContent('games.goose_game.penance_104', timerSeconds: 60),
  GooseContent('games.goose_game.penance_105', timerSeconds: 120),
  GooseContent('games.goose_game.penance_106'),
  GooseContent('games.goose_game.penance_107', timerSeconds: 60),
  GooseContent('games.goose_game.penance_108', timerSeconds: 30),
  GooseContent('games.goose_game.penance_109'),
  GooseContent('games.goose_game.penance_110'),
  GooseContent('games.goose_game.penance_111'),
  GooseContent('games.goose_game.penance_112'),
  GooseContent('games.goose_game.penance_113', timerSeconds: 180),
  GooseContent('games.goose_game.penance_114'),
  GooseContent('games.goose_game.penance_115'),
  GooseContent('games.goose_game.penance_116'),
];

// ==================== FINAL REWARDS (victory prizes, 30) ====================
//
// Each entry stores a translation key (games.goose_game.final_NNN).
// Call .tr() on `content.text` at display time to get the localized string.

const List<GooseContent> kFinalRewards = [
  GooseContent('games.goose_game.final_001'),
  GooseContent('games.goose_game.final_002'),
  GooseContent('games.goose_game.final_003'),
  GooseContent('games.goose_game.final_004'),
  GooseContent('games.goose_game.final_005'),
  GooseContent('games.goose_game.final_006'),
  GooseContent('games.goose_game.final_007'),
  GooseContent('games.goose_game.final_008'),
  GooseContent('games.goose_game.final_009'),
  GooseContent('games.goose_game.final_010'),
  GooseContent('games.goose_game.final_011'),
  GooseContent('games.goose_game.final_012'),
  GooseContent('games.goose_game.final_013'),
  GooseContent('games.goose_game.final_014'),
  GooseContent('games.goose_game.final_015'),
  GooseContent('games.goose_game.final_016'),
  GooseContent('games.goose_game.final_017'),
  GooseContent('games.goose_game.final_018'),
  GooseContent('games.goose_game.final_019'),
  GooseContent('games.goose_game.final_020', timerSeconds: 600),
  GooseContent('games.goose_game.final_021', timerSeconds: 300),
  GooseContent('games.goose_game.final_022'),
  GooseContent('games.goose_game.final_023'),
  GooseContent('games.goose_game.final_024'),
  GooseContent('games.goose_game.final_025', timerSeconds: 900),
  GooseContent('games.goose_game.final_026'),
  GooseContent('games.goose_game.final_027'),
  GooseContent('games.goose_game.final_028'),
  GooseContent('games.goose_game.final_029'),
  GooseContent('games.goose_game.final_030'),
];
