import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'data/providers/firebase_status_provider.dart';
import 'data/services/preferences_service.dart';
import 'data/services/user_data_sync_service.dart';
import 'data/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize localization
  await EasyLocalization.ensureInitialized();
  
  // Initialize preferences (SharedPreferences)
  await PreferencesService.instance.initialize();

  // Initialize audio service
  AudioService.instance.initialize();

  // Initialize Firebase. Fail-loud, not fail-silent: if this fails the app
  // still runs, but login and cloud sync are OFF — record that fact so the UI
  // can show an explicit offline indicator (see firebaseAvailableProvider).
  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
    debugPrint('✅ Firebase inizializzato');

    // Start cloud sync (best-effort)
    UserDataSyncService.instance.start();
  } catch (e, stackTrace) {
    firebaseAvailable = false;
    debugPrint(
      '⚠️ Firebase NON disponibile — la app gira in modalità offline: '
      'login e sync cloud sono DISATTIVATI. Causa: $e',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A0A1F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('pt'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('it'),
      child: ProviderScope(
        overrides: [
          firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
        ],
        child: const KamasutraApp(),
      ),
    ),
  );
}
