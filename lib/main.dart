import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screens.dart';
import 'core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await settings.load();
  runApp(const CampusFindApp());
}

class CampusFindApp extends StatelessWidget {
  const CampusFindApp({super.key});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF0A1610) : const Color(0xFFF6F8FB);
    final card = dark ? const Color(0xFF14261D) : Colors.white;
    final border = dark ? const Color(0xFF244235) : const Color(0xFFDCEBE1);
    final ink = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final muted = dark ? Colors.white60 : Colors.black54;

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kGreen,
        brightness: b,
        primary: kGreen,
        secondary: kDeep,
        surface: card,
      ),
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: ink),
      displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: ink),
      displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: ink),
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: ink),
      headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: ink),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(color: ink),
      bodyMedium: GoogleFonts.plusJakartaSans(color: ink),
      bodySmall: GoogleFonts.plusJakartaSans(color: muted),
      labelLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: ink),
      labelMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: ink),
      labelSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: muted),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.6),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'CampusFind UNESA',
          debugShowCheckedModeBanner: false,
          themeMode: settings.mode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(settings.fontScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}