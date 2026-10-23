import 'package:easy_localization/easy_localization.dart';

import '../../shared/game_kit.dart';

/// Wheel actions for one game, loaded from the localization files
/// (`games.wheel.cards.{category}.{intensity}.N`). Each category/intensity
/// pile is a shuffle bag, so an action only comes back once the pile has
/// been played through.
class WheelDeck {
  final _piles = <String, ShuffleBag<String>>{};

  String draw(String category, String intensity) {
    final pile = _piles.putIfAbsent(
      '$category.$intensity',
      () => ShuffleBag(localizedList('games.wheel.cards.$category.$intensity')),
    );
    if (pile.isEmpty) return 'games.wheel.fallback_action'.tr();
    return pile.next();
  }
}
