import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary       = Color(0xFF1DB8A0);
  static const Color primaryDark   = Color(0xFF0F8A78);
  static const Color secondary     = Color(0xFF2D3748);
  static const Color accent        = Color(0xFFFF8C42);
  static const Color background    = Color(0xFFF7F8FA);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color error         = Color(0xFFE53E3E);
  static const Color success       = Color(0xFF38A169);
  static const Color warning       = Color(0xFFDD6B20);
  static const Color textPrimary   = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color border        = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary:   primary,
        secondary: secondary,
        surface:   surface,
        error:     error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge:  GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge:    GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: surface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error)),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        hintStyle:  GoogleFonts.inter(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }
}
