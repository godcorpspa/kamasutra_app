import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/features/games/shared/game_kit.dart';
import 'package:kamasutra_app/shared/utils/display_text.dart';

void main() {
  group('ShuffleBag', () {
    test('hands out every item once before repeating any', () {
      final bag = ShuffleBag(List.generate(20, (i) => i), random: Random(1));
      final firstRound = {for (var i = 0; i < 20; i++) bag.next()};
      expect(firstRound, hasLength(20));
    });

    test('never repeats an item back to back across reshuffles', () {
      for (var seed = 0; seed < 50; seed++) {
        final bag = ShuffleBag([1, 2, 3], random: Random(seed));
        var last = bag.next();
        for (var i = 0; i < 30; i++) {
          final next = bag.next();
          expect(next, isNot(last), reason: 'seed $seed, draw $i');
          last = next;
        }
      }
    });

    test('a single-item bag keeps returning it', () {
      final bag = ShuffleBag(['only']);
      expect([bag.next(), bag.next()], ['only', 'only']);
    });
  });

  group('plainLabel', () {
    test('strips decorative emoji at the edges', () {
      expect(plainLabel('💬 Verità'), 'Verità');
      expect(plainLabel('Bollente! 🌋'), 'Bollente!');
    });

    test('keeps Spanish opening punctuation', () {
      expect(plainLabel('¡Hecho! Siguiente turno'), '¡Hecho! Siguiente turno');
      expect(plainLabel('🔥 ¿Listos?'), '¿Listos?');
    });
  });

  test('formatSeconds', () {
    expect(formatSeconds(45), '45');
    expect(formatSeconds(65), '1:05');
    expect(formatSeconds(120), '2:00');
  });
}
