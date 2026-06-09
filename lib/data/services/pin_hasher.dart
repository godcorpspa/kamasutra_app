import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Stateless cryptographic helper for the app-lock PIN.
///
/// Centralises PIN hashing so it can be unit-tested without booting a Widget
/// tree, and so any other code path that needs to validate a PIN uses the
/// exact same scheme (single source of truth — no copy-pasted salt strings or
/// iteration counts drifting between callers).
///
/// Scheme:
///   * Per-device random salt (16 bytes, base64-encoded).
///   * PBKDF2-HMAC-SHA256, 100 000 iterations, 32-byte derived key.
///   * Stored hash is prefixed with a version tag (`v2:`) so we can evolve
///     the scheme later without ambiguity.
///
/// Legacy hashes produced by the previous global-salt `sha256(pin + salt)`
/// scheme are still accepted by [verify]; callers should persist the upgrade
/// hash returned via [verifyAndUpgrade] so users transparently migrate to v2.
class PinHasher {
  PinHasher._();

  /// Version tag of the current scheme.
  static const String currentVersion = 'v2';

  /// PBKDF2 iteration count. A 4-digit PIN has only 10 000 possible inputs,
  /// so iterations slow offline guessing but don't replace storing the hash
  /// outside SharedPreferences (see flutter_secure_storage follow-up).
  static const int iterations = 100000;

  /// Length of the derived key, in bytes.
  static const int derivedKeyLength = 32;

  /// Length of the per-device salt, in bytes.
  static const int saltLength = 16;

  /// Legacy global salt used before the v2 scheme. Kept only to recognise
  /// pre-existing stored hashes during migration.
  static const String legacyGlobalSalt = 'kamasutra_salt_2024';

  /// Returns a fresh cryptographically-random salt, base64-encoded.
  ///
  /// [random] is exposed only for deterministic tests; production code should
  /// rely on the default `Random.secure()`.
  static String generateSalt({Random? random}) {
    final r = random ?? Random.secure();
    final bytes = List<int>.generate(saltLength, (_) => r.nextInt(256));
    return base64Encode(bytes);
  }

  /// Hashes [pin] with the v2 scheme and the given base64 [saltBase64].
  static String hash(String pin, String saltBase64) {
    final salt = base64Decode(saltBase64);
    final dk = _pbkdf2(utf8.encode(pin), salt, iterations, derivedKeyLength);
    return '$currentVersion:${base64Encode(dk)}';
  }

  /// Returns `true` iff [pin] matches [storedHash].
  ///
  /// Accepts both `v2:` hashes and the legacy `sha256(pin + legacyGlobalSalt)`
  /// form, so existing installs keep working.
  static bool verify(String pin, String storedHash, String saltBase64) {
    if (storedHash.startsWith('$currentVersion:')) {
      return _constantTimeEquals(storedHash, hash(pin, saltBase64));
    }
    return _constantTimeEquals(storedHash, _legacyHash(pin));
  }

  /// Like [verify], but also returns the up-to-date v2 hash so callers can
  /// persist it (transparent migration). Returns `null` when [pin] is wrong.
  static String? verifyAndUpgrade(
    String pin,
    String storedHash,
    String saltBase64,
  ) {
    if (!verify(pin, storedHash, saltBase64)) return null;
    return storedHash.startsWith('$currentVersion:')
        ? storedHash
        : hash(pin, saltBase64);
  }

  static String _legacyHash(String pin) =>
      sha256.convert(utf8.encode(pin + legacyGlobalSalt)).toString();

  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterationCount,
    int keyLength,
  ) {
    final prf = Hmac(sha256, password);
    final numBlocks = (keyLength / 32).ceil();
    final derived = <int>[];

    for (var block = 1; block <= numBlocks; block++) {
      final blockIndex = [
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = prf.convert([...salt, ...blockIndex]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterationCount; i++) {
        u = prf.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      derived.addAll(t);
    }
    return derived.sublist(0, keyLength);
  }

  /// Length-constant string comparison to avoid leaking via timing.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
