import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/data/services/pin_hasher.dart';

void main() {
  group('PinHasher.generateSalt', () {
    test('returns a 16-byte base64 string', () {
      final salt = PinHasher.generateSalt();
      final decoded = base64Decode(salt);
      expect(decoded.length, PinHasher.saltLength);
    });

    test('produces a different salt on each call (real entropy)', () {
      final a = PinHasher.generateSalt();
      final b = PinHasher.generateSalt();
      expect(a, isNot(equals(b)));
    });

    test('is deterministic when given a seeded Random (for tests only)', () {
      // Same seed → same salt; this is what makes the rest of the suite
      // reproducible. Production callers must NOT pass a seeded Random.
      final a = PinHasher.generateSalt(random: Random(42));
      final b = PinHasher.generateSalt(random: Random(42));
      expect(a, equals(b));
    });
  });

  group('PinHasher.hash', () {
    final salt = PinHasher.generateSalt(random: Random(1));

    test('returns the current versioned prefix', () {
      final h = PinHasher.hash('1234', salt);
      expect(h, startsWith('${PinHasher.currentVersion}:'));
    });

    test('is deterministic for the same (pin, salt)', () {
      expect(PinHasher.hash('1234', salt), PinHasher.hash('1234', salt));
    });

    test('different PINs with the same salt produce different hashes', () {
      expect(
        PinHasher.hash('1234', salt),
        isNot(PinHasher.hash('1235', salt)),
      );
    });

    test('same PIN with different salts produces different hashes', () {
      // This is the whole point of the per-device salt: a stolen prefs file
      // can't be cross-matched against another device's hash.
      final salt2 = PinHasher.generateSalt(random: Random(2));
      expect(
        PinHasher.hash('1234', salt),
        isNot(PinHasher.hash('1234', salt2)),
      );
    });

    test('decodes to a 32-byte derived key', () {
      final h = PinHasher.hash('1234', salt);
      final raw = base64Decode(h.split(':')[1]);
      expect(raw.length, PinHasher.derivedKeyLength);
    });
  });

  group('PinHasher.verify', () {
    final salt = PinHasher.generateSalt(random: Random(3));

    test('accepts the correct PIN', () {
      final h = PinHasher.hash('4321', salt);
      expect(PinHasher.verify('4321', h, salt), isTrue);
    });

    test('rejects an incorrect PIN', () {
      final h = PinHasher.hash('4321', salt);
      expect(PinHasher.verify('1234', h, salt), isFalse);
    });

    test('rejects the right PIN under the wrong salt', () {
      final h = PinHasher.hash('4321', salt);
      final wrongSalt = PinHasher.generateSalt(random: Random(99));
      expect(PinHasher.verify('4321', h, wrongSalt), isFalse);
    });

    test('accepts a legacy sha256(pin + globalSalt) hash', () {
      // Reproduce what the old code stored: sha256(pin + legacy salt).
      const pin = '0000';
      final legacyHash = sha256
          .convert(utf8.encode(pin + PinHasher.legacyGlobalSalt))
          .toString();

      // Legacy hashes don't depend on the device salt — any salt should work
      // because verify() only consults the device salt for v2 hashes.
      expect(PinHasher.verify(pin, legacyHash, salt), isTrue);
    });

    test('rejects a wrong PIN against a legacy hash', () {
      final legacyHash = sha256
          .convert(utf8.encode('0000' + PinHasher.legacyGlobalSalt))
          .toString();
      expect(PinHasher.verify('9999', legacyHash, salt), isFalse);
    });

    test('rejects an empty stored hash', () {
      expect(PinHasher.verify('1234', '', salt), isFalse);
    });
  });

  group('PinHasher.verifyAndUpgrade', () {
    final salt = PinHasher.generateSalt(random: Random(7));

    test('returns null on wrong PIN', () {
      final h = PinHasher.hash('1111', salt);
      expect(PinHasher.verifyAndUpgrade('2222', h, salt), isNull);
    });

    test('returns the same v2 hash when already on v2 scheme', () {
      // Right PIN, already migrated — caller has nothing new to persist.
      final h = PinHasher.hash('1111', salt);
      final upgraded = PinHasher.verifyAndUpgrade('1111', h, salt);
      expect(upgraded, equals(h));
    });

    test('returns a fresh v2 hash when a legacy hash matches', () {
      // Right PIN, legacy storage — caller should persist the upgrade.
      const pin = '5678';
      final legacyHash = sha256
          .convert(utf8.encode(pin + PinHasher.legacyGlobalSalt))
          .toString();
      final upgraded = PinHasher.verifyAndUpgrade(pin, legacyHash, salt);

      expect(upgraded, isNotNull);
      expect(upgraded, isNot(equals(legacyHash)));
      expect(upgraded, startsWith('${PinHasher.currentVersion}:'));
      // And the upgraded hash itself round-trips.
      expect(PinHasher.verify(pin, upgraded!, salt), isTrue);
    });
  });
}
