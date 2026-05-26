import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors from the screenshots
  static const Color primary = Color(0xFF8B0000);      // Dark crimson
  static const Color primaryDark = Color(0xFF6B0000);  // Darker crimson
  static const Color primaryLight = Color(0xFFAA2020); // Lighter crimson
  static const Color accent = Color(0xFFCC0000);       // Bright red accent
  static const Color success = Color(0xFF2E7D32);      // Green for OK
  static const Color danger = Color(0xFFC62828);       // Red for NG
  static const Color warning = Color(0xFFF57C00);      // Orange warning
  static const Color background = Color(0xFFF5F5F5);   // Light gray bg
  static const Color surface = Color(0xFFFFFFFF);      // White surface
  static const Color surfaceGray = Color(0xFFF0F0F0);  // Gray surface
  static const Color border = Color(0xFFE0E0E0);       // Border color
  static const Color textPrimary = Color(0xFF1A1A1A);  // Dark text
  static const Color textSecondary = Color(0xFF666666); // Gray text
  static const Color textLight = Color(0xFF999999);    // Light text
  static const Color sidebar = Color(0xFF1A1A1A);      // Sidebar dark
  static const Color sidebarActive = Color(0xFF8B0000); // Active sidebar item
  static const Color tableHeader = Color(0xFF2C2C2C);  // Table header
  static const Color tableRowAlt = Color(0xFFFFF8F8);  // Highlighted row
  static const Color pending = Color(0xFFE0E0E0);      // Pending gray

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: danger,
      ),
      textTheme: GoogleFonts.notoSansJpTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansJp(
          fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.notoSansJp(
          fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleLarge: GoogleFonts.notoSansJp(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleMedium: GoogleFonts.notoSansJp(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        bodyLarge: GoogleFonts.notoSansJp(
          fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary,
        ),
        bodyMedium: GoogleFonts.notoSansJp(
          fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary,
        ),
        bodySmall: GoogleFonts.notoSansJp(
          fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        toolbarHeight: 48,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          minimumSize: const Size(120, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 14, fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: GoogleFonts.notoSansJp(
          fontSize: 13, color: textLight,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border, thickness: 1, space: 0,
      ),
      scaffoldBackgroundColor: background,
    );
  }
}
