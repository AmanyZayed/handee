import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handee/theme/app_fonts.dart';

// ─── Color Tokens ──────────────────────────────────────────────────────────────
// Source: Handee Redesign.dc.html — deep-navy / electric-blue refresh

class AppColors {
  // ── Brand Blues ──
  static const Color royalNavy  = Color(0xFF062C66); // darkest brand blue
  static const Color primary    = Color(0xFF05347E); // main (buttons, links, focus)
  static const Color primaryMid = Color(0xFF1E5BB5); // gradient end for buttons
  static const Color electric   = Color(0xFF2C66C2); // lighter blue, icon accents
  static const Color cyan       = Color(0xFF16C8FF); // numbers, accent highlight

  // ── Dark Surfaces ──
  static const Color ink      = Color(0xFF0B1030); // nav bar bg
  static const Color inkDeep  = Color(0xFF070B22); // splash bg deepest

  // ── Light Backgrounds ──
  static const Color background = Color(0xFFF5F7FF); // screen bg
  static const Color mist       = Color(0xFFEEF2FF); // chip bg, icon bg, primary surface
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surface2   = Color(0xFFF0F3FB); // inactive mode buttons / input bg

  // ── Text ──
  static const Color textPrimary   = Color(0xFF0B1233);
  static const Color textSubtle    = Color(0xFF46506E); // labels, subtitles
  static const Color textSecondary = Color(0xFF5B6788); // body secondary
  static const Color textHint      = Color(0xFF9AA4C0); // placeholders, captions
  static const Color sectionLabel  = Color(0xFF7484AE); // row section headers

  // ── Borders / Dividers ──
  static const Color border  = Color(0xFFE6EAF7); // default input/card border
  static const Color divider = Color(0xFFE0E6F4); // dividers, progress track

  // ── Semantic ──
  static const Color success  = Color(0xFF22C55E);
  static const Color error    = Color(0xFFFF4D4D);
  static const Color errorDark = Color(0xFFE03333);
  static const Color warning  = Color(0xFFF59E0B);

  // ── Dark Mode ──
  static const Color darkBg            = Color(0xFF0B1124);
  static const Color darkSurface       = Color(0xFF161E38);
  static const Color darkSurface2      = Color(0xFF1A2440);
  static const Color darkBorder        = Color(0xFF283254);
  static const Color darkTextPrimary   = Color(0xFFEEF2FF);
  static const Color darkTextSecondary = Color(0xFF93A0C2);
  static const Color darkTextHint      = Color(0xFF6B779C);
  static const Color darkAccent        = Color(0xFF6FA0FF); // links / focus on dark

  // ── Shadows (pre-composed) ──
  // rgba(5,52,126,.16)  → 0x29 alpha
  // rgba(20,30,80,.07)  → 0x12 alpha
  static const Color shadowBlue = Color(0x2905347E);
  static const Color shadowCard = Color(0x12141E50);

  // ── Gradient Definitions ──
  // Primary button: LinearGradient(135°, [primary, primaryMid])
  // Brand icon:     LinearGradient(140°, [primary, electric])
  // Dark stage:     LinearGradient(160°, [0xFF16204F, 0xFF0C1336])

  // ── Legacy Aliases (keeps existing screen code compiling) ──
  static const Color primaryDark    = royalNavy;
  static const Color primaryDeep    = primary;
  static const Color primaryLight   = electric;
  static const Color primarySurface = mist;
  static const Color navBg          = ink;
  static const Color inputFill      = surface2;
  static const Color chipSelected   = primary;
  static const Color navBar         = ink;
  static const Color primaryDeep_   = primary;
  static const Color accent         = cyan;
  static const Color accent_        = cyan;
  static const Color shadow         = shadowBlue;
  static const Color shadowMd       = shadowCard;
  static const Color shadowDark     = Color(0x2B0B1030);
}

// ─── Spacing (8-point grid) ────────────────────────────────────────────────────

class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

// ─── Border Radius ─────────────────────────────────────────────────────────────

class AppRadius {
  static const double xs   = 8;   // small icons
  static const double sm   = 10;  // icon bg chips
  static const double md   = 12;  // back buttons, small cards
  static const double lg   = 16;  // inputs, buttons, chips
  static const double xl   = 20;  // small cards
  static const double xxl  = 24;  // main input cards
  static const double xxxl = 28;  // avatar stage, nav corners
  static const double pill = 100; // pill chips, badges
}

// ─── Shadows ───────────────────────────────────────────────────────────────────

class AppShadow {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowCard,
      blurRadius: 26,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.shadowBlue,
      blurRadius: 26,
      offset: Offset(0, 12),
    ),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: AppColors.shadowCard,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
  // kept for legacy callers
  static const List<BoxShadow> md = card;
  static const List<BoxShadow> lg = button;
  static List<BoxShadow> colored(Color c, {double opacity = 0.16}) => [
    BoxShadow(
      color: c.withValues(alpha: opacity),
      blurRadius: 26,
      offset: const Offset(0, 12),
    ),
  ];
}

// ─── Theme ─────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get theme {
    // Plus Jakarta Sans for all body/UI text
    final base = AppFonts.plusJakartaTextTheme();

    // Space Grotesk for display headings
    final displayFont = AppFonts.spaceGrotesk;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.electric,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,

      textTheme: base.copyWith(
        // Display — Space Grotesk (headers, wordmark)
        displayLarge: displayFont(
          fontSize: 44, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -1.5,
        ),
        displayMedium: displayFont(
          fontSize: 33, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.8,
        ),
        displaySmall: displayFont(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.6,
        ),
        headlineLarge: displayFont(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        headlineMedium: displayFont(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.3,
        ),
        headlineSmall: displayFont(
          fontSize: 17, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.2,
        ),
        // Body — Plus Jakarta Sans
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSubtle,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary, height: 1.55,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, height: 1.5,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 12.5, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, height: 1.5,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: base.labelMedium?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.3,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: AppColors.textHint, letterSpacing: 0.3,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppFonts.plusJakarta(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSubtle,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppFonts.plusJakarta(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppFonts.plusJakarta(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: AppFonts.plusJakarta(
          color: AppColors.textSubtle,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: AppFonts.plusJakarta(
          color: AppColors.textHint,
          fontSize: 15,
        ),
        floatingLabelStyle: AppFonts.plusJakarta(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      chipTheme: ChipThemeData(
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.mist,
        disabledColor: AppColors.surface2,
        labelStyle: AppFonts.plusJakarta(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        showCheckmark: false,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppFonts.plusJakarta(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.divider,
        thumbColor: AppColors.surface,
        overlayColor: Color(0x2005347E),
      ),
    );
  }

  // Dark theme — same structure, dark tokens
  static ThemeData get darkTheme {
    final base = AppFonts.plusJakartaTextTheme(
      ThemeData.dark().textTheme,
    );
    final displayFont = AppFonts.spaceGrotesk;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryMid,
        onPrimary: Colors.white,
        secondary: AppColors.electric,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,

      textTheme: base.copyWith(
        displayMedium: displayFont(
          fontSize: 33, fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary, letterSpacing: -0.8,
        ),
        displaySmall: displayFont(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary, letterSpacing: -0.6,
        ),
        headlineMedium: displayFont(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary, letterSpacing: -0.3,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary, height: 1.55,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary, height: 1.5,
        ),
        labelMedium: base.labelMedium?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}
