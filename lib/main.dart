import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screens.dart';
import 'core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await settings.load();
    await store.load();
  } catch (e) {
    debugPrint('Init error: $e');
  }
  runApp(const CampusFindApp());
}

ThemeData _theme(Brightness b) {
  final dark = b == Brightness.dark;
  final bar = dark ? const Color(0xFF111A2E) : Colors.white;
  final bg = dark ? const Color(0xFF090F1D) : const Color(0xFFF6F8FB);

  String? bodyFont;
  String? headingFont;
  try {
    bodyFont = GoogleFonts.instrumentSans().fontFamily;
    headingFont = GoogleFonts.bricolageGrotesque().fontFamily;
  } catch (_) {}

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    fontFamily: bodyFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF10B981),
      brightness: b,
      surface: bar,
    ),
    scaffoldBackgroundColor: bg,
    cardTheme: CardThemeData(
      color: bar,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: dark ? 0.45 : 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bar,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: headingFont ?? bodyFont,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: dark ? Colors.white : const Color(0xFF0F172A),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bar,
      indicatorColor: dark
          ? const Color(0xFF10B981).withValues(alpha: 0.25)
          : const Color(0xFF10B981).withValues(alpha: 0.15),
    ),
  );
}

class CampusFindApp extends StatelessWidget {
  const CampusFindApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      title: 'CampusFind',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: settings.mode,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          textScaler: TextScaler.linear(settings.fontScale),
        ),
        child: child!,
      ),
      home: const SplashScreen(),
    ),
  );
}