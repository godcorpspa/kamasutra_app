import 'package:flutter/material.dart';

/// App color palette based on design system
class AppColors {
  // Primary colors
  static const Color burgundy = Color(0xFF722F37);
  static const Color burgundyLight = Color(0xFF8B4049);
  static const Color burgundyDark = Color(0xFF5A252C);
  
  // Secondary colors
  static const Color navy = Color(0xFF1B365D);
  static const Color navyLight = Color(0xFF2A4A7A);
  static const Color navyDark = Color(0xFF122440);
  
  // Accent colors
  static const Color blush = Color(0xFFF4C2C2);
  static const Color blushLight = Color(0xFFFAE0E0);
  static const Color cream = Color(0xFFFFF8E7);
  static const Color gold = Color(0xFFD4A574);
  static const Color goldLight = Color(0xFFE5C49A);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  static const Color black = Color(0xFF000000);
  
  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Intensity colors
  static const Color softPink = Color(0xFFFFB6C1);    // 🌸 Soft
  static const Color spicyOrange = Color(0xFFFF6B35); // 🔥 Spicy
  static const Color extraSpicyRed = Color(0xFFDC143C); // 🌶️ Extra Spicy
  
  // Intensity color aliases
  static const Color soft = softPink;
  static const Color spicy = spicyOrange;
  static const Color extraSpicy = extraSpicyRed;
  
  // Semantic text colors
  static const Color textPrimary = grey900;
  static const Color textSecondary = grey600;
  
  // Surface and background colors
  static const Color surface = white;
  static const Color background = offWhite;
  
  // Additional accent colors
  static const Color romantic = blush;
  static const Color accent = gold;
  
  // Dark theme specific - Viola/Fucsia erotico
  static const Color darkBackground = Color(0xFF1A0A1F);  // Viola scuro
  static const Color darkSurface = Color(0xFF2D1536);     // Viola medio
  static const Color darkCard = Color(0xFF3D2046);        // Viola card
  
  // Additional purple/fuchsia colors
  static const Color purple = Color(0xFF6B2D5B);
  static const Color purpleLight = Color(0xFF8B4078);
  static const Color purpleDark = Color(0xFF4A1D40);
  static const Color fuchsia = Color(0xFFD946EF);
  static const Color fuchsiaLight = Color(0xFFE879F9);
  static const Color fuchsiaDark = Color(0xFFA21CAF);
}

/// App animation durations
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// App typography using Playfair Display and DM Sans
class AppTypography {
  static const String displayFont = 'PlayfairDisplay';
  static const String bodyFont = 'DMSans';
  
  static TextTheme get textTheme => const TextTheme(
    // Display styles (Playfair Display)
    displayLarge: TextStyle(
      fontFamily: displayFont,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: displayFont,
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontFamily: displayFont,
      fontSize: 36,
      fontWeight: FontWeight.w400,
    ),
    
    // Headline styles (Playfair Display)
    headlineLarge: TextStyle(
      fontFamily: displayFont,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      fontFamily: displayFont,
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: TextStyle(
      fontFamily: displayFont,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    
    // Title styles (DM Sans)
    titleLarge: TextStyle(
      fontFamily: bodyFont,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      fontFamily: bodyFont,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: bodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    
    // Body styles (DM Sans)
    bodyLarge: TextStyle(
      fontFamily: bodyFont,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: bodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: bodyFont,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    
    // Label styles (DM Sans)
    labelLarge: TextStyle(
      fontFamily: bodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: bodyFont,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: bodyFont,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}

/// App theme configuration
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Colors
    colorScheme: const ColorScheme.light(
      primary: AppColors.burgundy,
      primaryContainer: AppColors.burgundyLight,
      secondary: AppColors.navy,
      secondaryContainer: AppColors.navyLight,
      tertiary: AppColors.gold,
      tertiaryContainer: AppColors.goldLight,
      surface: AppColors.cream,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.grey900,
      onError: AppColors.white,
    ),
    
    scaffoldBackgroundColor: AppColors.cream,
    
    // Typography
    textTheme: AppTypography.textTheme,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.burgundy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.burgundy,
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.burgundy,
        foregroundColor: AppColors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.burgundy,
        side: const BorderSide(color: AppColors.burgundy, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.burgundy,
        textStyle: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.burgundy,
      unselectedItemColor: AppColors.grey500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.burgundy, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey100,
      selectedColor: AppColors.burgundy,
      labelStyle: const TextStyle(
        fontFamily: AppTypography.bodyFont,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.grey200,
      thickness: 1,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Colors - Viola/Fucsia erotico
    colorScheme: const ColorScheme.dark(
      primary: AppColors.fuchsiaLight,
      primaryContainer: AppColors.purple,
      secondary: AppColors.blush,
      secondaryContainer: AppColors.purpleDark,
      tertiary: AppColors.gold,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: AppColors.grey900,
      onSecondary: AppColors.grey900,
      onSurface: AppColors.cream,
      onError: AppColors.white,
    ),
    
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    // Typography
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.cream,
      displayColor: AppColors.cream,
    ),
    
    // AppBar - Viola
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.purple,
      foregroundColor: AppColors.cream,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.cream,
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Buttons - Viola/Fucsia
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: AppColors.cream,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.fuchsiaLight,
        side: const BorderSide(color: AppColors.fuchsiaLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blush,
        textStyle: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Bottom Navigation - Viola
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.fuchsiaLight,
      unselectedItemColor: AppColors.grey500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Input - Viola
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purpleLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purpleLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.fuchsia, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // Chips - Viola
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkCard,
      selectedColor: AppColors.purple,
      labelStyle: const TextStyle(
        fontFamily: AppTypography.bodyFont,
        fontSize: 14,
        color: AppColors.cream,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.grey800,
      thickness: 1,
    ),
  );
}

/// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius constants
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double round = 100;
}

/// Animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}
