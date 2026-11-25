import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Pengontrol global mode Siang (false) / Malam (true)
final ValueNotifier<bool> isNightModeNotifier = ValueNotifier<bool>(false);

class AppTheme {
  // Tema Siang (Cerah, bersih, aksen hijau & biru kampus)
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final fontName = GoogleFonts.plusJakartaSans().fontFamily;
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F8F6),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B8A5A),
        brightness: Brightness.light,
      ),
      textTheme: base.textTheme.apply(fontFamily: fontName),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D5C9E),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // Tema Malam (Gelap elegan, kontras nyaman di mata, aksen emas & biru malam)
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final fontName = GoogleFonts.plusJakartaSans().fontFamily;
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B121E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2EC486),
        brightness: Brightness.dark,
        surface: const Color(0xFF131D2E),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontName,
        bodyColor: const Color(0xFFE8EEF5),
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF131D2E),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0B1322),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}