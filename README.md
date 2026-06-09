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

> ⚠️ If a Firebase API key was ever committed to git history, rotate it in the
> Firebase console (Project settings → General → Web API key / regenerate) and
> purge it from history before publishing the repository.
