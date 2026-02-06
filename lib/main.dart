import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'data/services/preferences_service.dart';
import 'data/services/firebase_user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize localization
  await EasyLocalization.ensureInitialized();
  
  // Initialize local preferences (for PIN, age gate, etc.)
  await PreferencesService.instance.initialize();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    
    // Initialize Firestore with offline persistence
    await FirebaseUserService.initialize();
    
    debugPrint('✅ Firebase inizializzato con persistenza offline');
  } catch (e) {
    debugPrint('⚠️ Firebase non disponibile: $e');
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
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('it'),
      child: const ProviderScope(
        child: KamasutraApp(),
      ),
    ),
  );
}
