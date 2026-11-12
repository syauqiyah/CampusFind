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
  final bar = dark ? const Color(0xFF0F1F17) : Colors.white;
  TextTheme baseText = ThemeData(brightness: b).textTheme;
  try {
    baseText = GoogleFonts.interTextTheme(baseText);
  } catch (_) {}

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: ColorScheme.fromSeed(seedColor: kGreen, brightness: b),
    scaffoldBackgroundColor: dark ? const Color(0xFF0A1510) : const Color(0xFFF3FAF5),
    textTheme: baseText,
    appBarTheme: AppBarTheme(backgroundColor: bar, elevation: 0, scrolledUnderElevation: 0),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: bar, indicatorColor: dark ? kGreen.withOpacity(.35) : kLeaf),
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
            data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
            child: child!,
          ),
          home: const SplashScreen(),
        ),
      );
}
