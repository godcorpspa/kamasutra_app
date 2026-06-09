import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Firebase initialised successfully at app startup.
///
/// The real value is injected in `main()` via a `ProviderScope` override.
/// When `false`, the app runs in **local-only mode**: email/Google login and
/// cloud sync are unavailable. UI should read this provider and surface an
/// explicit "offline mode" indicator instead of silently pretending that data
/// is being synced to the cloud.
final firebaseAvailableProvider = Provider<bool>(
  (ref) => throw UnimplementedError(
    'firebaseAvailableProvider must be overridden in main() with the real '
    'Firebase init result.',
  ),
);
