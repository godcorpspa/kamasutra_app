import 'package:easy_localization/easy_localization.dart';

import '../../shared/game_kit.dart';

/// Truths and dares for one game, loaded from the localization files
/// (`games.truth_dare.cards.{truths|dares}.{intensity}.N`).
///
/// Each pile is a shuffle bag: no card comes back until the whole pile has
/// been played, and "change card" never hands out the same one again.
class TruthDareDeck {
  final _piles = <String, ShuffleBag<String>>{};

  String draw({required bool truth, required String intensity}) {
    final kind = truth ? 'truths' : 'dares';
    final pile = _piles.putIfAbsent(
      '$kind.$intensity',
      () => ShuffleBag(localizedList('games.truth_dare.cards.$kind.$intensity')),
    );
    if (pile.isEmpty) {
      return 'games.truth_dare.cards.fallback_${truth ? 'truth' : 'dare'}'
          .tr();
    }
    return pile.next();
  }
}
