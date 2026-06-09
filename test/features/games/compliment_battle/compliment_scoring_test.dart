import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/features/games/compliment_battle/domain/compliment_scoring.dart';

void main() {
  group('ComplimentScoring.basePoints', () {
    test('great (2) = 12, ok (1) = 6, weak (0) = 0', () {
      expect(ComplimentScoring.basePoints(2), 12);
      expect(ComplimentScoring.basePoints(1), 6);
      expect(ComplimentScoring.basePoints(0), 0);
    });

    test('unexpected high judgement clamps to the "great" tier', () {
      expect(ComplimentScoring.basePoints(5), 12);
    });

    test('negative judgement scores nothing', () {
      expect(ComplimentScoring.basePoints(-1), 0);
    });
  });

  group('ComplimentScoring.streakMultiplier', () {
    test('boundaries: <3 = 1x, 3-4 = 1.5x, >=5 = 2x', () {
      expect(ComplimentScoring.streakMultiplier(0), 1.0);
      expect(ComplimentScoring.streakMultiplier(2), 1.0);
      expect(ComplimentScoring.streakMultiplier(3), 1.5);
      expect(ComplimentScoring.streakMultiplier(4), 1.5);
      expect(ComplimentScoring.streakMultiplier(5), 2.0);
      expect(ComplimentScoring.streakMultiplier(9), 2.0);
    });
  });

  group('ComplimentScoring.judge', () {
    test('weak judgement scores 0, breaks streak, no compliment counted', () {
      final r = ComplimentScoring.judge(
        judgment: 0,
        timeRemaining: 30,
        currentStreak: 4,
        bonusRound: true,
      );
      expect(r.points, 0);
      expect(r.newStreak, 0);
      expect(r.complimentRegistered, isFalse);
    });

    test('ok judgement: base 6 + time bonus, streak advances to 1', () {
      // time bonus = ceil(20 / 4) = 5 ; multiplier(1) = 1.0
      final r = ComplimentScoring.judge(
        judgment: 1,
        timeRemaining: 20,
        currentStreak: 0,
        bonusRound: false,
      );
      expect(r.points, 11); // 6 + 5
      expect(r.newStreak, 1);
      expect(r.complimentRegistered, isTrue);
    });

    test('time bonus rounds up (ceil)', () {
      // ceil(1/4) = 1
      final r = ComplimentScoring.judge(
        judgment: 1,
        timeRemaining: 1,
        currentStreak: 0,
        bonusRound: false,
      );
      expect(r.points, 7); // 6 + 1
    });

    test('great judgement at streak 2 -> streak 3 applies the 1.5x tier', () {
      // base 12 + ceil(8/4)=2 => 14 ; *1.5 = 21
      final r = ComplimentScoring.judge(
        judgment: 2,
        timeRemaining: 8,
        currentStreak: 2,
        bonusRound: false,
      );
      expect(r.newStreak, 3);
      expect(r.points, 21);
    });

    test('streak 4 -> 5 applies the 2x tier', () {
      // base 12 + ceil(0/4)=0 => 12 ; *2.0 = 24
      final r = ComplimentScoring.judge(
        judgment: 2,
        timeRemaining: 0,
        currentStreak: 4,
        bonusRound: false,
      );
      expect(r.newStreak, 5);
      expect(r.points, 24);
    });

    test('bonus round doubles after the streak multiplier', () {
      // base 12 + ceil(8/4)=2 => 14 ; *1.5 (streak 3) = 21 ; *2 bonus = 42
      final r = ComplimentScoring.judge(
        judgment: 2,
        timeRemaining: 8,
        currentStreak: 2,
        bonusRound: true,
      );
      expect(r.points, 42);
    });

    test('negative timeRemaining is treated as zero (no negative bonus)', () {
      final r = ComplimentScoring.judge(
        judgment: 1,
        timeRemaining: -10,
        currentStreak: 0,
        bonusRound: false,
      );
      expect(r.points, 6); // base only
    });

    test('result value-equality works (for clean assertions)', () {
      expect(
        ComplimentScoring.judge(
          judgment: 1,
          timeRemaining: 0,
          currentStreak: 0,
          bonusRound: false,
        ),
        const ComplimentScoreResult(
          points: 6,
          newStreak: 1,
          complimentRegistered: true,
        ),
      );
    });
  });
}
