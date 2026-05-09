import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 2026 colour tokens
  static const Color primary     = Color(0xFF1DB8A0); // Fleetara Teal
  static const Color primaryDark = Color(0xFF0F8A78); // Teal Dark
  static const Color darkNavy    = Color(0xFF1E2A3A); // Dark Navy
  static const Color amber       = Color(0xFFEF9F27); // Amber
  static const Color rose        = Color(0xFFE24B4A); // Rose Red
  static const Color emerald     = Color(0xFF639922); // Emerald
  static const Color surface     = Color(0xFFFFFFFF); // Surface
  static const Color background  = Color(0xFFF7F8FA); // Background
  static const Color border      = Color(0xFFE2E8F0); // Border
  static const Color textPrimary = Color(0xFF1A202C); // Text Primary
  static const Color textMuted   = Color(0xFF718096); // Text Muted

  // Aliases
  static const Color secondary = darkNavy;
  static const Color error     = rose;
  static const Color success   = emerald;
  static const Color warning   = amber;
  static const Color accent    = amber;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary:   primary,
        secondary: darkNavy,
        surface:   surface,
        error:     rose,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge:  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: textPrimary),
        titleLarge:    GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        titleMedium:   GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium:    GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
        bodySmall:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted),
        labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: textMuted),
        labelLarge:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: surface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        shape: const Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(minHeight: 36),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: rose, width: 0.5)),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: textMuted),
        hintStyle:  GoogleFonts.inter(fontSize: 12, color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: 10),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primary.withValues(alpha: 0.18),
        labelStyle: GoogleFonts.inter(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: border, width: 0.5),
        showCheckmark: false,
      ),
    );
  }
}
