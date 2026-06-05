import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Spacing scale (4pt base).
class Insets {
  const Insets._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class Radii {
  const Radii._();
  static const double sm = 10;
  static const double md = 18;
  static const double lg = 28;
  static const double pill = 999;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: AppPalette.textPrimary,
      displayColor: AppPalette.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppPalette.surface,
        primary: AppPalette.reaction,
        secondary: AppPalette.focus,
        error: AppPalette.danger,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.sora(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppPalette.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppPalette.textPrimary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
    );
  }
}
