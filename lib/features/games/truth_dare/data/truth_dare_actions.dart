import 'dart:math';
import 'package:easy_localization/easy_localization.dart';

/// Repository of all truth and dare actions organized by intensity.
/// Each category has 20 items per intensity level, loaded from localization files.
class TruthDareActions {
  static final _random = Random();

  static String getTruth(String intensity) {
    final key = 'games.truth_dare.cards.truths.$intensity';
    // Try to get localized list
    final list = _getLocalizedList(key);
    if (list.isEmpty) return 'games.truth_dare.cards.fallback_truth'.tr();
    return list[_random.nextInt(list.length)];
  }

  static String getDare(String intensity) {
    final key = 'games.truth_dare.cards.dares.$intensity';
    final list = _getLocalizedList(key);
    if (list.isEmpty) return 'games.truth_dare.cards.fallback_dare'.tr();
    return list[_random.nextInt(list.length)];
  }

  static List<String> _getLocalizedList(String key) {
    final List<String> results = [];
    for (int i = 0; i < 20; i++) {
      final translated = '$key.$i'.tr();
      // If the key is not found, easy_localization returns the key itself
      if (translated != '$key.$i') {
        results.add(translated);
      }
    }
    return results;
  }
}
