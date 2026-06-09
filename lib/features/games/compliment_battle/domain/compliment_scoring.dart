/// Outcome of judging a single compliment.
///
/// Immutable value object so it can be asserted on directly in tests.
class ComplimentScoreResult {
  const ComplimentScoreResult({
    required this.points,
    required this.newStreak,
    required this.complimentRegistered,
  });

  /// Points awarded for this round (after streak + bonus-round multipliers).
  final int points;

  /// The player's streak after this judgement (0 if the compliment failed).
  final int newStreak;

  /// Whether this counts as a delivered compliment (judgement was positive).
  final bool complimentRegistered;

  @override
  bool operator ==(Object other) =>
      other is ComplimentScoreResult &&
      other.points == points &&
      other.newStreak == newStreak &&
      other.complimentRegistered == complimentRegistered;

  @override
  int get hashCode => Object.hash(points, newStreak, complimentRegistered);

  @override
  String toString() =>
      'ComplimentScoreResult(points: $points, newStreak: $newStreak, '
      'complimentRegistered: $complimentRegistered)';
}

/// Pure scoring rules for the Compliment Battle game.
///
/// Extracted from the screen's `_judgeCompliment` so the (fiddly) point maths —
/// base points, time bonus, streak multipliers and bonus-round doubling — can
/// be unit-tested in isolation, with no `setState`, timers or animations.
class ComplimentScoring {
  const ComplimentScoring._();

  /// Base points awarded for the partner's [judgment]:
  /// `2` = great (👍), `1` = ok (👌), anything else = weak (👎).
  static int basePoints(int judgment) {
    if (judgment >= 2) return 12;
    if (judgment == 1) return 6;
    return 0;
  }

  /// Streak multiplier: 5+ in a row doubles, 3+ adds 50%.
  static double streakMultiplier(int streak) {
    if (streak >= 5) return 2.0;
    if (streak >= 3) return 1.5;
    return 1.0;
  }

  /// Computes the result of judging a compliment.
  ///
  /// - [judgment]: partner's rating (2/1/other).
  /// - [timeRemaining]: seconds left on the clock (adds a small time bonus).
  /// - [currentStreak]: the judged player's streak *before* this round.
  /// - [bonusRound]: whether this round's points are doubled.
  static ComplimentScoreResult judge({
    required int judgment,
    required int timeRemaining,
    required int currentStreak,
    required bool bonusRound,
  }) {
    // A non-positive judgement scores nothing and breaks the streak.
    if (judgment <= 0) {
      return const ComplimentScoreResult(
        points: 0,
        newStreak: 0,
        complimentRegistered: false,
      );
    }

    // Base + time bonus (1 point per 4 seconds remaining, rounded up).
    final safeTime = timeRemaining < 0 ? 0 : timeRemaining;
    var points = basePoints(judgment) + (safeTime / 4).ceil();

    final newStreak = currentStreak + 1;
    points = (points * streakMultiplier(newStreak)).round();

    if (bonusRound) points *= 2;

    return ComplimentScoreResult(
      points: points,
      newStreak: newStreak,
      complimentRegistered: true,
    );
  }
}
