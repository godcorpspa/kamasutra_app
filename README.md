# Kamasutra & Couple Games

A Flutter app of intimate couple games and a position catalog, with optional
Firebase-backed login and multi-device cloud sync.

## Getting Started

```bash
flutter pub get
flutter run
```

## Firebase setup (required for login / cloud sync)

Firebase config files contain project credentials and are **not** committed to
the repository. Each developer / CI environment must provide them locally:

- `android/app/google-services.json` — from Firebase console → Project settings
  → your Android app.
- `ios/Runner/GoogleService-Info.plist` — same, for the iOS app.

Without these files the app still runs, but login and cloud sync are disabled
(Firebase initialization fails open — see `lib/main.dart`).

### Security rules

Firestore and Storage rules live in `firestore.rules` and `storage.rules`.
They restrict every read/write to the authenticated owner's `users/{uid}`
subtree. Deploy them with:

```bash
firebase deploy --only firestore:rules,storage
```

### Privacy: intimate notes stay on the device

Free-text notes attached to history entries (the most sensitive field in the
app) are NEVER mirrored to Firestore. The client skips the field on write
and the Firestore rules reject any history write that includes a `notes`
key, as defence in depth against stale or malicious clients. The first time
an upgraded client signs in it purges any `notes` field a previous version
may have already written to the cloud, so the rest of the history sync
(favourites, streaks, position views) still works without leaving legacy
plaintext behind.

> ⚠️ If a Firebase API key was ever committed to git history, rotate it in the
> Firebase console (Project settings → General → Web API key / regenerate) and
> purge it from history before publishing the repository.
