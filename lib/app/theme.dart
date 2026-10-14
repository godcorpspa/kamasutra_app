import 'package:flutter/material.dart';

/// App color palette.
///
/// The app is dark-only and follows a "midnight velvet" direction: a warm,
/// almost-black plum canvas, ivory text, champagne/rosé accents and muted
/// jewel tones. Saturated neons and candy gradients are deliberately avoided
/// — they read as playful/childish rather than intimate and adult.
class AppColors {
  // ── Canvas & surfaces (darkest → lightest) ──────────────────────────────
  static const Color ink = Color(0xFF0E0A0D); // app background
  static const Color inkRaised = Color(0xFF161015); // cards, nav bar
  static const Color inkHigh = Color(0xFF1F171D); // inputs, sheets, dialogs
  static const Color inkHighest = Color(0xFF2A2027); // selected / pressed

  /// Hairline borders and dividers (ivory at ~10%).
  static const Color hairline = Color(0x1AF4ECE3);

  /// Slightly stronger outline for interactive controls (ivory at ~22%).
  static const Color outline = Color(0x38F4ECE3);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color ivory = Color(0xFFF4ECE3); // primary text
  static const Color mist = Color(0xFFB9ABB2); // secondary text
  static const Color smoke = Color(0xFF7E7079); // tertiary text, idle icons

  // ── Accents ─────────────────────────────────────────────────────────────
  static const Color champagne = Color(0xFFE9C9A6); // primary accent
  static const Color rose = Color(0xFFD9958A); // secondary accent
  static const Color wine = Color(0xFF8E2C48); // brand
  static const Color wineLight = Color(0xFFC25A72); // brand, readable on ink
  static const Color onAccent = Color(0xFF2A1520); // text on champagne

  /// Paper tone behind position illustrations ("art print" plates).
  static const Color parchment = Color(0xFFEDE3D8);

  /// Signature gradient for primary emphasis (exactly two stops).
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [champagne, rose],
  );

  // ── Muted jewel tones (categories, games) ───────────────────────────────
  static const Color jewelRose = Color(0xFFD9958A);
  static const Color jewelSand = Color(0xFFCDB58C);
  static const Color jewelEmber = Color(0xFFE0895A);
  static const Color jewelDusk = Color(0xFF8FA8C8);
  static const Color jewelSage = Color(0xFFA6BFA2);
  static const Color jewelGarnet = Color(0xFFD0405C);
  static const Color jewelLilac = Color(0xFFB79AD6);
  static const Color jewelAmber = Color(0xFFE2C46B);
  static const Color jewelTeal = Color(0xFF8CC2B4);

  // ── Legacy tokens ───────────────────────────────────────────────────────
  // Still referenced by the individual games' own art direction.
  static const Color burgundy = Color(0xFF722F37);
  static const Color burgundyLight = Color(0xFF8B4049);
  static const Color burgundyDark = Color(0xFF5A252C);
  static const Color navy = Color(0xFF1B365D);
  static const Color navyLight = Color(0xFF2A4A7A);
  static const Color navyDark = Color(0xFF122440);
  static const Color blush = Color(0xFFF4C2C2);
  static const Color blushLight = Color(0xFFFAE0E0);
  static const Color cream = ivory;
  static const Color gold = Color(0xFFD4A574);
  static const Color goldLight = Color(0xFFE5C49A);

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

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF8CC2A0);
  static const Color warning = Color(0xFFE2C46B);
  static const Color error = Color(0xFFE5737F);
  static const Color info = Color(0xFF8FA8C8);

  // ── Intensity (muted, not neon) ─────────────────────────────────────────
  static const Color softPink = Color(0xFFE8A3B4);
  static const Color spicyOrange = Color(0xFFE0895A);
  static const Color extraSpicyRed = Color(0xFFD0405C);
  static const Color soft = softPink;
  static const Color spicy = spicyOrange;
  static const Color extraSpicy = extraSpicyRed;

  static const Color textPrimary = ivory;
  static const Color textSecondary = mist;
  static const Color surface = inkRaised;
  static const Color background = ink;
  static const Color romantic = rose;
  static const Color accent = champagne;

  static const Color darkBackground = ink;
  static const Color darkSurface = inkRaised;
  static const Color darkCard = inkHigh;

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

/// Typography: Playfair Display (editorial serif) for display and headlines,
/// DM Sans for everything the user reads or taps.
class AppTypography {
  static const String displayFont = 'PlayfairDisplay';
  static const String bodyFont = 'DMSans';

  /// Playfair defaults to old-style figures (a small "1", a descending
  /// "3"); lining figures read cleaner in counters, PINs and stats.
  static const List<FontFeature> lining = [FontFeature.liningFigures()];

  /// Small uppercase, widely tracked label used above sections
  /// ("ACCOUNT", "PRIVACY"…). Gives structure without visual weight.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
    color: AppColors.smoke,
  );

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontFamily: displayFont,
          fontFeatures: lining,
          fontSize: 52,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.0,
          height: 1.05,
        ),
        displayMedium: TextStyle(
          fontFamily: displayFont,
          fontFeatures: lining,
          fontSize: 42,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.8,
          height: 1.08,
        ),
        displaySmall: TextStyle(
          fontFamily: displayFont,
          fontFeatures: lining,
          fontSize: 34,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        headlineLarge: TextStyle(
          fontFamily: displayFont,
          fontFeatures: lining,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          height: 1.15,
        ),
        headlineMedium: TextStyle(
          fontFamily: displayFont,
          fontFeatures: lining,
          fontSize: 27,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.18,
        ),
        headlineSmall: TextStyle(
          fontFamily: displayFont,
          fontFeatures: lining,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontFamily: displayFont,
          fontFeatures: lining,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        titleMedium: TextStyle(
          fontFamily: bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontFamily: bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontFamily: bodyFont,
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
          height: 1.4,
          color: AppColors.mist,
        ),
        labelLarge: TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          fontFamily: bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontFamily: bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: AppColors.mist,
        ),
      );
}

/// App theme configuration. The app is dark-only (see app.dart).
class AppTheme {
  /// Kept for API compatibility; the app always renders the dark theme.
  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: AppColors.champagne,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.wine,
      onPrimaryContainer: AppColors.ivory,
      secondary: AppColors.rose,
      onSecondary: AppColors.onAccent,
      secondaryContainer: AppColors.inkHighest,
      onSecondaryContainer: AppColors.ivory,
      tertiary: AppColors.wineLight,
      onTertiary: AppColors.ivory,
      surface: AppColors.inkRaised,
      onSurface: AppColors.ivory,
      onSurfaceVariant: AppColors.mist,
      surfaceContainerLowest: AppColors.ink,
      surfaceContainerLow: AppColors.inkRaised,
      surfaceContainer: AppColors.inkRaised,
      surfaceContainerHigh: AppColors.inkHigh,
      surfaceContainerHighest: AppColors.inkHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.hairline,
      error: AppColors.error,
      onError: AppColors.onAccent,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final textTheme = AppTypography.textTheme.apply(
      bodyColor: AppColors.ivory,
      displayColor: AppColors.ivory,
    );

    const stadium = StadiumBorder();
    const buttonPadding = EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    const buttonText = TextStyle(
      fontFamily: AppTypography.bodyFont,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ink,
      canvasColor: AppColors.ink,
      fontFamily: AppTypography.bodyFont,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: const IconThemeData(color: AppColors.ivory, size: 22),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ivory,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.displayFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ivory,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.inkRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.champagne,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.inkHighest,
          disabledForegroundColor: AppColors.smoke,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: buttonPadding,
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.champagne,
          foregroundColor: AppColors.onAccent,
          padding: buttonPadding,
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ivory,
          side: const BorderSide(color: AppColors.outline),
          padding: buttonPadding,
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.champagne,
          shape: stadium,
          textStyle: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.ivory),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inkHigh,
        hintStyle: const TextStyle(color: AppColors.smoke),
        labelStyle: const TextStyle(color: AppColors.mist),
        floatingLabelStyle: const TextStyle(color: AppColors.champagne),
        prefixIconColor: AppColors.smoke,
        suffixIconColor: AppColors.smoke,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.champagne),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),

      chipTheme: const ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.champagne,
        disabledColor: AppColors.inkHigh,
        side: BorderSide(color: AppColors.outline),
        labelStyle: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.ivory,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onAccent,
        ),
        checkmarkColor: AppColors.onAccent,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: StadiumBorder(),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.onAccent
                : AppColors.mist),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.champagne
                : AppColors.inkHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.transparent
                : AppColors.outline),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.champagne,
        inactiveTrackColor: AppColors.inkHighest,
        thumbColor: AppColors.champagne,
        overlayColor: Color(0x22E9C9A6),
        trackHeight: 3,
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        valueIndicatorColor: AppColors.inkHighest,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.champagne,
        linearTrackColor: AppColors.inkHighest,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.ivory,
        unselectedLabelColor: AppColors.smoke,
        indicatorColor: AppColors.champagne,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.hairline,
        labelStyle: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.mist,
        textColor: AppColors.ivory,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.inkHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.hairline),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: AppTypography.displayFont,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.ivory,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 14.5,
          height: 1.5,
          color: AppColors.mist,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.inkHigh,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.inkHigh,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ivory,
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onAccent,
        ),
        actionTextColor: AppColors.wine,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.inkHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.inkHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(color: AppColors.ivory, fontSize: 12),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.champagne,
        textColor: AppColors.onAccent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.inkRaised,
        selectedItemColor: AppColors.champagne,
        unselectedItemColor: AppColors.smoke,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
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
  static const double xl = 22;
  static const double round = 100;
}

/// Animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}
