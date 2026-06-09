import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/data/models/position.dart';
import 'package:kamasutra_app/data/providers/providers.dart';

Position _pos(String id) => Position(
      id: id,
      nameIt: id,
      nameEn: id,
      categories: const [PositionCategory.romantic],
      difficulty: 1,
      energy: EnergyLevel.low,
      focus: const [PositionFocus.intimacy],
      duration: PositionDuration.brief,
      illustrationRef: 'ref',
    );

void main() {
  group('ShuffleSession (navigation value object)', () {
    final three = [_pos('a'), _pos('b'), _pos('c')];

    test('empty session has no current position and no neighbours', () {
      final s = ShuffleSession(positions: const []);
      expect(s.currentPosition, isNull);
      expect(s.hasNext, isFalse);
      expect(s.hasPrevious, isFalse);
    });

    test('at the first index: current = first, next yes, previous no', () {
      final s = ShuffleSession(positions: three, currentIndex: 0);
      expect(s.currentPosition?.id, 'a');
      expect(s.hasNext, isTrue);
      expect(s.hasPrevious, isFalse);
    });

    test('in the middle: both neighbours exist', () {
      final s = ShuffleSession(positions: three, currentIndex: 1);
      expect(s.currentPosition?.id, 'b');
      expect(s.hasNext, isTrue);
      expect(s.hasPrevious, isTrue);
    });

    test('at the last index: previous yes, next no', () {
      final s = ShuffleSession(positions: three, currentIndex: 2);
      expect(s.currentPosition?.id, 'c');
      expect(s.hasNext, isFalse);
      expect(s.hasPrevious, isTrue);
    });

    test('an out-of-range index yields a null current position', () {
      final s = ShuffleSession(positions: three, currentIndex: 3);
      expect(s.currentPosition, isNull);
    });

    test('copyWith overrides only the given fields', () {
      final s = ShuffleSession(
        positions: three,
        currentIndex: 0,
        sessionId: 'sess-1',
      );
      final moved = s.copyWith(currentIndex: 2);

      expect(moved.currentIndex, 2);
      expect(moved.positions, same(s.positions));
      expect(moved.sessionId, 'sess-1');
      expect(moved.isComplete, isFalse);
      // Original is untouched (value semantics).
      expect(s.currentIndex, 0);
    });
  });
}
