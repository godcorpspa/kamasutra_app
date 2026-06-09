import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/data/models/position.dart';

/// Builds a Position with sensible defaults; override only what a test cares
/// about. Keeps the (large) Position constructor out of every test body.
Position pos({
  String id = 'p',
  String nameIt = 'Loto',
  String nameEn = 'Lotus',
  List<PositionCategory> categories = const [PositionCategory.romantic],
  int difficulty = 3,
  EnergyLevel energy = EnergyLevel.medium,
  List<PositionFocus> focus = const [PositionFocus.intimacy],
  PositionDuration duration = PositionDuration.medium,
  List<String> tags = const [],
  String? aliasEn,
  String? cautionsEn,
  bool isFavorite = false,
}) {
  return Position(
    id: id,
    nameIt: nameIt,
    nameEn: nameEn,
    aliasEn: aliasEn,
    categories: categories,
    difficulty: difficulty,
    energy: energy,
    focus: focus,
    duration: duration,
    tags: tags,
    cautionsEn: cautionsEn,
    illustrationRef: 'ref',
    isFavorite: isFavorite,
  );
}

void main() {
  group('PositionFilter.isEmpty', () {
    test('a bare filter is empty', () {
      expect(const PositionFilter().isEmpty, isTrue);
    });

    test('an empty search string still counts as empty', () {
      expect(const PositionFilter(searchQuery: '').isEmpty, isTrue);
    });

    test('any set slice makes it non-empty', () {
      expect(const PositionFilter(minDifficulty: 2).isEmpty, isFalse);
    });
  });

  group('PositionFilter.apply', () {
    final all = [
      pos(id: 'a', difficulty: 1, energy: EnergyLevel.low),
      pos(id: 'b', difficulty: 3, energy: EnergyLevel.medium),
      pos(id: 'c', difficulty: 5, energy: EnergyLevel.high),
    ];

    List<String> ids(List<Position> ps) => ps.map((p) => p.id).toList();

    test('an empty filter returns everything', () {
      expect(ids(const PositionFilter().apply(all)), ['a', 'b', 'c']);
    });

    test('difficulty range is inclusive on both bounds', () {
      const f = PositionFilter(minDifficulty: 3, maxDifficulty: 5);
      expect(ids(f.apply(all)), ['b', 'c']);
    });

    test('minDifficulty alone excludes easier positions', () {
      const f = PositionFilter(minDifficulty: 3);
      expect(ids(f.apply(all)), ['b', 'c']);
    });

    test('energy filter matches the single level', () {
      const f = PositionFilter(energyLevels: [EnergyLevel.high]);
      expect(ids(f.apply(all)), ['c']);
    });

    test('category filter keeps positions sharing ANY selected category', () {
      final list = [
        pos(id: 'rom', categories: const [PositionCategory.romantic]),
        pos(id: 'ath', categories: const [PositionCategory.athletic]),
        pos(
          id: 'both',
          categories: const [
            PositionCategory.romantic,
            PositionCategory.adventurous,
          ],
        ),
      ];
      const f = PositionFilter(categories: [PositionCategory.adventurous]);
      expect(ids(f.apply(list)), ['both']);
    });

    test('favoritesOnly keeps only favourites', () {
      final list = [
        pos(id: 'fav', isFavorite: true),
        pos(id: 'plain'),
      ];
      const f = PositionFilter(favoritesOnly: true);
      expect(ids(f.apply(list)), ['fav']);
    });

    test('excludeCautions drops positions that carry a caution', () {
      final list = [
        pos(id: 'safe'),
        pos(id: 'risky', cautionsEn: 'mind your back'),
      ];
      const f = PositionFilter(excludeCautions: true);
      expect(ids(f.apply(list)), ['safe']);
    });

    test('search matches name case-insensitively', () {
      final list = [pos(id: 'lotus', nameEn: 'Lotus'), pos(id: 'arch', nameEn: 'Arch')];
      const f = PositionFilter(searchQuery: 'LOT');
      expect(ids(f.apply(list)), ['lotus']);
    });

    test('search matches alias and tags too', () {
      final list = [
        pos(id: 'byAlias', nameEn: 'X', aliasEn: 'Butterfly'),
        pos(id: 'byTag', nameEn: 'Y', tags: const ['butterfly']),
        pos(id: 'noMatch', nameEn: 'Z'),
      ];
      const f = PositionFilter(searchQuery: 'butterfly');
      expect(ids(f.apply(list)), ['byAlias', 'byTag']);
    });

    test('multiple slices AND together', () {
      final list = [
        pos(id: 'hit', difficulty: 4, energy: EnergyLevel.high, isFavorite: true),
        pos(id: 'wrongFav', difficulty: 4, energy: EnergyLevel.high),
        pos(id: 'wrongDiff', difficulty: 1, energy: EnergyLevel.high, isFavorite: true),
      ];
      const f = PositionFilter(
        minDifficulty: 3,
        energyLevels: [EnergyLevel.high],
        favoritesOnly: true,
      );
      expect(ids(f.apply(list)), ['hit']);
    });

    test('does not mutate the input list', () {
      final list = [pos(id: 'a', difficulty: 1), pos(id: 'b', difficulty: 5)];
      const PositionFilter(minDifficulty: 3).apply(list);
      expect(ids(list), ['a', 'b']);
    });
  });
}
