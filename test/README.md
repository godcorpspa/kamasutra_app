# Tests

Test infrastructure for the Kamasutra app. The folder layout mirrors `lib/`
so every test sits next to the unit under test:

```
test/
├── data/
│   ├── models/
│   │   └── position_filter_apply_test.dart     # Catalog filter matching
│   ├── providers/
│   │   ├── position_filter_notifier_test.dart  # Riverpod StateNotifier logic
│   │   └── shuffle_session_test.dart           # Shuffle navigation value object
│   └── services/
│       └── pin_hasher_test.dart                # PIN hashing + legacy migration
└── features/
    └── games/
        └── compliment_battle/
            └── compliment_scoring_test.dart    # Scoring formula + multipliers
```

## Running

```bash
flutter test
```

Single file:

```bash
flutter test test/data/services/pin_hasher_test.dart
```

## Conventions

- **Unit-first.** Pure-Dart units (notifiers, hashers, parsers) get a real test;
  widgets only get a smoke test unless their logic is non-trivial.
- **No Firebase in tests.** Anything that touches `FirebaseAuth.instance` or
  `FirebaseFirestore.instance` must be wrapped behind an interface that can be
  faked. Tests never boot Firebase.
- **No SharedPreferences singleton in tests.** When a target needs prefs,
  refactor it to accept the dependency (constructor or parameter) and pass a
  fake in. `PinHasher` is the reference shape for this.
- **Deterministic randomness.** Cryptographic helpers accept an optional
  `Random` so tests can seed it. Production callers must never pass one.
