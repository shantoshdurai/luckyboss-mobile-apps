import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryNavy    = Color(0xFF0B1B3D);
  static const Color navy           = primaryNavy;
  static const Color emerald        = Color(0xFF059669);
  static const Color emeraldLight   = Color(0xFF10B981);
  static const Color royalBlue      = Color(0xFF2563EB);
  static const Color amber          = Color(0xFFD97706);
  static const Color bgPaper        = Color(0xFFF8FAFC);
  static const Color surfaceWhite   = Color(0xFFFFFFFF);
  static const Color borderLight    = Color(0xFFE2E8F0);
  static const Color textPrimary    = Color(0xFF0F172A);
  static const Color textSecondary  = Color(0xFF475569);
  static const Color textMuted      = Color(0xFF94A3B8);

  // Dark Colors
  static const Color bgDark         = Color(0xFF0B132B);
  static const Color cardDark       = Color(0xFF1E293B);
  static const Color borderDark     = Color(0xFF334155);
  static const Color textDarkPrim   = Color(0xFFF8FAFC);

  static TextStyle serifTitle({double fontSize = 22, Color color = textPrimary}) =>
      GoogleFonts.cormorantGaramond(fontSize: fontSize, fontWeight: FontWeight.w700, color: color);

  static TextStyle sansBold({double fontSize = 14, Color color = textPrimary}) =>
      GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: FontWeight.w700, color: color);

  static TextStyle sansMedium({double fontSize = 13, Color color = textSecondary}) =>
      GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: FontWeight.w500, color: color);

  static TextStyle sansRegular({double fontSize = 13.5, Color color = textSecondary}) =>
      GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: FontWeight.w400, color: color);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryNavy,
      scaffoldBackgroundColor: bgPaper,
      cardColor: surfaceWhite,
      dividerColor: borderLight,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: emerald,
        surface: surfaceWhite,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryNavy),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: primaryNavy),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: emerald,
      scaffoldBackgroundColor: bgDark,
      cardColor: cardDark,
      dividerColor: borderDark,
      colorScheme: const ColorScheme.dark(
        primary: emerald,
        secondary: emeraldLight,
        surface: cardDark,
        onPrimary: Colors.white,
        onSurface: textDarkPrim,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDarkPrim),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textDarkPrim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}