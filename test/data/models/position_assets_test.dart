import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/data/models/position.dart';

/// Guards the bundled catalogue: every locale file must parse with the real
/// model, ids must be unique, and the numbered setup steps must line up
/// across languages (the detail screen renders them step by step).
void main() {
  const locales = ['it', 'en', 'es', 'fr', 'pt'];
  final stepStart = RegExp(r'^\s*\d+[.)]\s*', multiLine: true);

  int stepCount(String? text) => text == null
      ? 0
      : text.split(stepStart).where((s) => s.trim().isNotEmpty).length;

  for (final file in locales) {
    test('positions_$file.json parses and is consistent', () {
      final raw = File('assets/positions/positions_$file.json').readAsStringSync();
      final positions = (json.decode(raw) as List)
          .map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(positions, isNotEmpty);
      final ids = positions.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate ids');

      for (final p in positions) {
        expect(p.categories, isNotEmpty, reason: p.id);
        expect(p.focus, isNotEmpty, reason: p.id);
        expect(p.difficulty, inInclusiveRange(1, 5), reason: p.id);
        final steps = stepCount(p.getSetup('it'));
        for (final locale in locales) {
          expect(p.getName(locale).trim(), isNotEmpty, reason: '${p.id} $locale');
          expect(stepCount(p.getSetup(locale)), steps,
              reason: '${p.id} setup steps in $locale');
        }
      }
    });
  }
}
