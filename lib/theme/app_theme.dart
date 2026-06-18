import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Colour tokens — mirroring the CSS :root variables in legacy_web_code/src/styles.css
// ---------------------------------------------------------------------------
abstract final class CrickifyColors {
  // Backgrounds
  static const Color pitchDeep = Color(0xFF07160F);
  static const Color pitch = Color(0xFF0E3B25);
  static const Color scoreboard = Color(0xFF101812);
  static const Color scoreboard2 = Color(0xFF16251B);

  // Text / UI
  static const Color sight = Color(0xFFFFF7DF);
  static const Color cream = Color(0xFFF3EAD0);
  static const Color muted = Color(0xFFB8C5B7);

  // Accent — golden rope
  static const Color rope = Color(0xFFD8A536);
  static const Color ropeLight = Color(0xFFF1C85A);

  // Status
  static const Color grass = Color(0xFF2FB26F);
  static const Color danger = Color(0xFFEF7A52);
  static const Color good = Color(0xFF43D17E);

  // Dividers / borders
  static const Color line = Color(0x29FFF7DF); // rgba(255,247,223,0.16)
}

// ---------------------------------------------------------------------------
// Typography — defined with plain TextStyle.
// The Inter font family is applied globally via MaterialApp.theme in main.dart
// using GoogleFonts.interTextTheme() once the package is available.
// All styles here use fontFamily: 'Inter' as a hint; Flutter falls back to the
// system sans-serif if the font isn't registered yet.
// ---------------------------------------------------------------------------
abstract final class CrickifyTextStyles {
  // Internal base — no package dependency needed here
  static const TextStyle _base = TextStyle(fontFamily: 'Inter');

  // Hero / title
  static const TextStyle hero = TextStyle(
    fontFamily: 'Inter',
    color: CrickifyColors.sight,
    fontWeight: FontWeight.w900,
    fontSize: 48,
    height: 0.92,
  );

  // Section heading inside panels
  static const TextStyle sectionHeading = TextStyle(
    fontFamily: 'Inter',
    color: CrickifyColors.sight,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    height: 1.08,
  );

  // Eyebrow label (ALL CAPS small label above headings)
  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'Inter',
    color: CrickifyColors.ropeLight,
    fontWeight: FontWeight.w900,
    fontSize: 11,
    letterSpacing: 1.2,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    color: CrickifyColors.cream,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.55,
  );

  // Muted / secondary body
  static const TextStyle bodyMuted = TextStyle(
    fontFamily: 'Inter',
    color: CrickifyColors.muted,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.55,
  );

  // Score / large number display
  static const TextStyle scoreDisplay = TextStyle(
    fontFamily: 'Inter',
    color: CrickifyColors.ropeLight,
    fontWeight: FontWeight.w900,
    fontSize: 48,
    height: 0.85,
  );

  // Button label
  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w900,
    fontSize: 15,
    letterSpacing: 0.2,
  );

  // Small metadata label
  static const TextStyle meta = TextStyle(
    fontFamily: 'Inter',
    color: CrickifyColors.muted,
    fontWeight: FontWeight.w900,
    fontSize: 11,
    letterSpacing: 0.5,
  );
}

// ---------------------------------------------------------------------------
// Reusable decorations — card surfaces used throughout the app
// ---------------------------------------------------------------------------
abstract final class CrickifyDecorations {
  // Standard dark card (matches .broadcast-card in CSS).
  // BoxDecoration cannot have both `color` and `gradient` — dark background
  // is encoded as the second gradient stop.
  static const BoxDecoration card = BoxDecoration(
    border: Border.fromBorderSide(
      BorderSide(color: CrickifyColors.line, width: 1),
    ),
    borderRadius: BorderRadius.all(Radius.circular(8)),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x0BFFFFFF), // subtle top sheen
        Color(0xF0101812), // scoreboard ~94% opacity
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x57000000),
        blurRadius: 70,
        offset: Offset(0, 24),
      ),
    ],
  );

  // Match callout — gold-tinted panel
  static const BoxDecoration matchCallout = BoxDecoration(
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x5CF1C85A), width: 1),
    ),
    borderRadius: BorderRadius.all(Radius.circular(8)),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x1FF1C85A), // rope 12%
        Color(0x0FFFF7DF), // sight 6%
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// App ThemeData — no external package imports needed
// ---------------------------------------------------------------------------
abstract final class CrickifyTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CrickifyColors.pitchDeep,

      colorScheme: const ColorScheme.dark(
        surface: CrickifyColors.pitchDeep,
        primary: CrickifyColors.ropeLight,
        primaryContainer: CrickifyColors.rope,
        secondary: CrickifyColors.grass,
        error: CrickifyColors.danger,
        onPrimary: Color(0xFF17210F),
        onSurface: CrickifyColors.sight,
        onSecondary: CrickifyColors.pitchDeep,
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: CrickifyTextStyles.hero,
        displayMedium: TextStyle(
          fontFamily: 'Inter',
          color: CrickifyColors.sight,
          fontWeight: FontWeight.w900,
          fontSize: 36,
          height: 0.92,
        ),
        headlineLarge: CrickifyTextStyles.sectionHeading,
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          color: CrickifyColors.sight,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          height: 1.08,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          color: CrickifyColors.sight,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          height: 1.55,
        ),
        bodyLarge: CrickifyTextStyles.body,
        bodyMedium: CrickifyTextStyles.bodyMuted,
        labelLarge: CrickifyTextStyles.button,
        labelSmall: CrickifyTextStyles.meta,
      ),

      // Primary action button — solid golden background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CrickifyColors.ropeLight,
          foregroundColor: const Color(0xFF17210F),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: Color(0xFF17210F),
          ),
          elevation: 8,
          shadowColor: Colors.black45,
        ),
      ),

      // Outlined secondary button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CrickifyColors.sight,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: const BorderSide(
            color: Color(0x6BF1C85A), // ropeLight ~42%
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0x0FFFF7DF), // sight ~6%
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: CrickifyColors.sight,
          ),
        ),
      ),

      // Text input — dark glass style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14FFF7DF), // sight ~8%
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        constraints: const BoxConstraints(minHeight: 54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0x2EFFF7DF), // sight ~18%
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0x2EFFF7DF), // sight ~18%
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CrickifyColors.ropeLight,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0x8AFFF7DF), // sight ~54%
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          color: CrickifyColors.cream,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),

      // Snack bars / toasts
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF25150F),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFFFFD8CA),
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: CrickifyColors.line,
        thickness: 1,
        space: 0,
      ),

      // Icon defaults
      iconTheme: const IconThemeData(
        color: CrickifyColors.cream,
        size: 20,
      ),
    );
  }
}
