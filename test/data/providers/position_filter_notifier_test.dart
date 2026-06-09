import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/data/models/position.dart';
import 'package:kamasutra_app/data/providers/providers.dart';

void main() {
  group('PositionFilterNotifier', () {
    late PositionFilterNotifier notifier;

    setUp(() => notifier = PositionFilterNotifier());

    test('starts with an empty filter', () {
      expect(notifier.state, const PositionFilter());
    });

    test('setCategories updates the categories slice', () {
      notifier.setCategories([PositionCategory.romantic]);
      expect(notifier.state.categories, [PositionCategory.romantic]);
      // Other slices stay untouched.
      expect(notifier.state.minDifficulty, isNull);
      expect(notifier.state.energyLevels, isNull);
    });

    test('setDifficultyRange updates both bounds', () {
      notifier.setDifficultyRange(2, 4);
      expect(notifier.state.minDifficulty, 2);
      expect(notifier.state.maxDifficulty, 4);
    });

    test('setEnergy wraps a single value into a list, or nulls it out', () {
      notifier.setEnergy(EnergyLevel.high);
      expect(notifier.state.energyLevels, [EnergyLevel.high]);

      notifier.setEnergy(null);
      expect(notifier.state.energyLevels, isNull);
    });

    test('setFavoritesOnly toggles the flag', () {
      notifier.setFavoritesOnly(true);
      expect(notifier.state.favoritesOnly, true);
      notifier.setFavoritesOnly(false);
      expect(notifier.state.favoritesOnly, false);
    });

    test('setSearchQuery preserves every other slice', () {
      // Seed every slice so we can prove they all survive a search update.
      notifier.setCategories([PositionCategory.romantic]);
      notifier.setDifficultyRange(1, 3);
      notifier.setEnergy(EnergyLevel.medium);
      notifier.setFavoritesOnly(true);

      notifier.setSearchQuery('lotus');

      expect(notifier.state.searchQuery, 'lotus');
      expect(notifier.state.categories, [PositionCategory.romantic]);
      expect(notifier.state.minDifficulty, 1);
      expect(notifier.state.maxDifficulty, 3);
      expect(notifier.state.energyLevels, [EnergyLevel.medium]);
      expect(notifier.state.favoritesOnly, true);
    });

    test('clear resets every slice', () {
      notifier.setCategories([PositionCategory.romantic]);
      notifier.setDifficultyRange(2, 5);
      notifier.setSearchQuery('lotus');

      notifier.clear();
      expect(notifier.state, const PositionFilter());
    });

    test('setAll replaces the whole state at once', () {
      notifier.setAll(
        categories: [PositionCategory.romantic],
        minDifficulty: 1,
        maxDifficulty: 4,
        energyLevels: [EnergyLevel.high],
        favoritesOnly: true,
        searchQuery: 'kama',
      );

      expect(notifier.state.categories, [PositionCategory.romantic]);
      expect(notifier.state.minDifficulty, 1);
      expect(notifier.state.maxDifficulty, 4);
      expect(notifier.state.energyLevels, [EnergyLevel.high]);
      expect(notifier.state.favoritesOnly, true);
      expect(notifier.state.searchQuery, 'kama');
    });
  });
}
