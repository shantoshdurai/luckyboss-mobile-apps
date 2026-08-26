import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryNavy    = Color(0xFF0B1B3D);
  static const Color navy           = primaryNavy;
  static const Color navyDark       = Color(0xFF051026);
  static const Color navyLight      = Color(0xFF162B56);
  static const Color emerald        = Color(0xFF10B981);
  static const Color emeraldDark    = Color(0xFF059669);
  static const Color emeraldLight   = Color(0xFFD1FAE5);
  static const Color royalBlue      = Color(0xFF2563EB);
  static const Color skyBlue        = Color(0xFF0EA5E9);
  static const Color amber          = Color(0xFFF59E0B);
  static const Color amberLight      = Color(0xFFFEF3C7);
  
  static const Color bgPaper        = Color(0xFFF8FAFC);
  static const Color surfaceWhite   = Color(0xFFFFFFFF);
  static const Color surfaceMuted   = Color(0xFFF1F5F9);
  static const Color borderLight    = Color(0xFFE2E8F0);
  static const Color borderMedium   = Color(0xFFCBD5E1);
  
  static const Color textPrimary    = Color(0xFF0F172A);
  static const Color textSecondary  = Color(0xFF475569);
  static const Color textMuted      = Color(0xFF94A3B8);

  // Dark Theme Colors
  static const Color bgDark         = Color(0xFF0B132B);
  static const Color surfaceDark    = Color(0xFF1C2541);
  static const Color cardDark       = Color(0xFF1E293B);
  static const Color borderDark     = Color(0xFF334155);
  static const Color textDarkPrim   = Color(0xFFF8FAFC);
  static const Color textDarkSec    = Color(0xFF94A3B8);

  static TextStyle serifTitle({double fontSize = 24, Color color = textPrimary, FontWeight fontWeight = FontWeight.w700}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.2,
    );
  }

  static TextStyle sansBold({double fontSize = 14, Color color = textPrimary, double? letterSpacing}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sansSemiBold({double fontSize = 14, Color color = textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle sansMedium({double fontSize = 13, Color color = textSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle sansRegular({double fontSize = 13.5, Color color = textSecondary, double? height}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      height: height ?? 1.45,
    );
  }

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
        tertiary: royalBlue,
        surface: surfaceWhite,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: primaryNavy),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primaryNavy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
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
        secondary: emeraldDark,
        tertiary: skyBlue,
        surface: cardDark,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDarkPrim,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black45,
        iconTheme: const IconThemeData(color: textDarkPrim),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDarkPrim,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}