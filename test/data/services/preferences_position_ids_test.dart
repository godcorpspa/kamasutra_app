import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/data/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved lists swap removed positions for the ones that replaced them',
      () async {
    SharedPreferences.setMockInitialValues({
      'tried_positions': ['pos_001', 'pos_014', 'pos_034', 'pos_008'],
      'favorite_positions': ['pos_005', 'pos_022'],
    });
    final prefs = PreferencesService.instance;
    await prefs.initialize();

    expect(prefs.triedPositionIds, ['pos_001', 'pos_034', 'pos_123']);
    expect(prefs.favoritePositionIds, ['pos_027', 'pos_123']);
    expect(prefs.isFavorite('pos_027'), isTrue);

    await prefs.removeTriedPosition('pos_034');
    expect(prefs.triedPositionIds, ['pos_001', 'pos_123']);
  });
}
