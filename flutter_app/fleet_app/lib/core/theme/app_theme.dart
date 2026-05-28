import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand palette — sourced from Fleetara logo ─────────────────────────────
  // Logo: deep navy shield (#1A2B5C) + royal blue accents (#2354C8)
  static const Color primary     = Color(0xFF1E3A72); // Logo Navy Blue
  static const Color primaryDark = Color(0xFF132B5E); // Deeper Navy
  static const Color accent      = Color(0xFF2563EB); // Royal Blue (CTAs)
  static const Color darkNavy    = Color(0xFF0D1B3E); // Sidebar / hero bg

  // ── Semantic colours ───────────────────────────────────────────────────────
  static const Color amber   = Color(0xFFF59E0B); // Warning
  static const Color rose    = Color(0xFFEF4444); // Error / Critical
  static const Color emerald = Color(0xFF16A34A); // Success / Pass

  // ── Surface & layout ──────────────────────────────────────────────────────
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF0F4FA); // Blue-tinted off-white
  static const Color border     = Color(0xFFDDE4F0); // Navy-tinted border

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F1B3D); // Near-black navy
  static const Color textMuted   = Color(0xFF6074A1); // Muted blue-gray

  // ── Aliases ────────────────────────────────────────────────────────────────
  static const Color secondary = darkNavy;
  static const Color error     = rose;
  static const Color success   = emerald;
  static const Color warning   = amber;

  // ── Elevation helpers ──────────────────────────────────────────────────────
  // Subtle card shadow with a navy tint — use on Container decorations.
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0F1E3A72), // navy @ ~6 %
        blurRadius: 20,
        spreadRadius: 0,
        offset: Offset(0, 6),
      ),
      BoxShadow(
        color: Color(0x081E3A72), // navy @ ~3 %
        blurRadius: 4,
        spreadRadius: 0,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Slightly more prominent for hero/large cards
  static BoxDecoration get cardDecorationMd => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0x141E3A72), // navy @ ~8 %
        blurRadius: 28,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: Color(0x0A1E3A72),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary:   primary,
        secondary: accent,
        surface:   surface,
        error:     rose,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
        bodySmall:    GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted),
        labelSmall:   GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: textMuted),
        labelLarge:   GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: surface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x101E3A72),
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        shape: const Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,          // Royal blue for primary actions
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          side: const BorderSide(color: border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(minHeight: 40),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border, width: 0.8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border, width: 0.8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: rose, width: 0.8)),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: textMuted),
        hintStyle:  GoogleFonts.inter(fontSize: 12, color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: const Color(0x0E1E3A72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.only(bottom: 10),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: accent.withValues(alpha: 0.14),
        labelStyle: GoogleFonts.inter(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: border, width: 0.5),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 20,
        shadowColor: const Color(0x1A1E3A72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
