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

## Release checklist (Android)

Before shipping a store build, two steps that CANNOT be automated in this
repo must be completed:

1. **Pick the final `applicationId`.** It is still the placeholder
   `com.example.kamasutra_app_new` (`android/app/build.gradle.kts`) —
   Google Play rejects `com.example.*` IDs and the ID can never be changed
   after the first upload. After choosing it, register an Android app with
   the same package name in the Firebase console and download the matching
   `google-services.json`.
2. **Create the release keystore.** Signing config is read from
   `android/key.properties` (gitignored):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

   ```properties
   # android/key.properties
   storeFile=/absolute/path/to/upload-keystore.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   Without `key.properties` the release build falls back to the debug keys
   (fine for `flutter run --release`, never publishable).

Finally run `flutter analyze && flutter test` and a real
`flutter build appbundle --release` on a physical device.
