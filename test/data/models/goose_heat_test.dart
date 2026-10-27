import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/data/models/goose_game.dart';

void main() {
  test('every reward and penance has exactly one heat level', () {
    final rewards = [for (var h = 1; h <= 4; h++) ...gooseRewards(h)];
    final penances = [for (var h = 1; h <= 4; h++) ...goosePenances(h)];
    expect(rewards.map((c) => c.text).toSet(), kRewards.map((c) => c.text).toSet());
    expect(rewards, hasLength(kRewards.length));
    expect(penances.map((c) => c.text).toSet(), kPenances.map((c) => c.text).toSet());
    expect(penances, hasLength(kPenances.length));
  });

  test('heat levels map to the right cards', () {
    // Spot checks: a foot massage warms up, oral sex is the top level.
    expect(gooseRewards(1).map((c) => c.text), contains('games.goose_game.reward_002'));
    expect(gooseRewards(4).map((c) => c.text), contains('games.goose_game.reward_036'));
    expect(goosePenances(1).map((c) => c.text), contains('games.goose_game.penance_009'));
    expect(goosePenances(4).map((c) => c.text), contains('games.goose_game.penance_027'));
  });

  test('the board heats up by quarters', () {
    expect(gooseHeatForSquare(1), 1);
    expect(gooseHeatForSquare(25), 1);
    expect(gooseHeatForSquare(26), 2);
    expect(gooseHeatForSquare(50), 2);
    expect(gooseHeatForSquare(51), 3);
    expect(gooseHeatForSquare(76), 4);
    expect(gooseHeatForSquare(100), 4);
  });
}
