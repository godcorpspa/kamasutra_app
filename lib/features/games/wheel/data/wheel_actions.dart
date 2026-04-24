import 'dart:math';
import 'package:easy_localization/easy_localization.dart';

/// Repository of all wheel actions organized by category and intensity.
/// Each category has 20 actions per intensity level, loaded from localization files.
class WheelActions {
  static final _random = Random();

  /// Returns a random action for the given category key and intensity.
  static String getAction(String categoryKey, String intensity, String locale) {
    final list = _getLocalizedList('games.wheel.cards.$categoryKey.$intensity');
    if (list.isEmpty) return 'games.wheel.fallback_action'.tr();
    return list[_random.nextInt(list.length)];
  }

  static List<String> _getLocalizedList(String key) {
    final List<String> results = [];
    for (int i = 0; i < 20; i++) {
      final translated = '$key.$i'.tr();
      if (translated != '$key.$i') {
        results.add(translated);
      }
    }
    return results;
  }
}
