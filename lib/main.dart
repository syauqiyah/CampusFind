import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_screens.dart';
import 'core.dart';
import 'device_notif.dart';
import 'firebase_options.dart';
import 'guard_screens.dart';
import 'splash_screen.dart';
import 'student_screens.dart';
import 'unesa_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await DeviceNotif.init();

  await settings.load();
  await UnesaLogoCache.ensureLoaded();

  await store.restoreSession();
  if (store.isLoggedIn) {
    await store.load();
  }

  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  runApp(const CampusFindApp());
}

TextTheme _buildCleanTextTheme(Brightness brightness) {
  final isDarkMode = brightness == Brightness.dark;
  final primaryText =
  isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  final secondaryText =
  isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

  return TextTheme(
    headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: primaryText,
        letterSpacing: -0.6,
        height: 1.2),
    headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: primaryText,
        letterSpacing: -0.5,
        height: 1.25),
    titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: primaryText,
        letterSpacing: -0.3),
    titleMedium: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: -0.2),
    titleSmall:
    TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: primaryText),
    bodyLarge: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: primaryText,
        height: 1.45),
    bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        height: 1.45),
    bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        height: 1.4),
    labelLarge:
    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
  );
}

class CampusFindApp extends StatelessWidget {
  const CampusFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget initialTarget = store.isLoggedIn
        ? (store.guard ? const GuardShell() : const StudentShell())
        : const ChooseLoginScreen();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final bool dark = settings.mode == ThemeMode.dark;

        return MaterialApp(
          title: 'CampusFind UNESA',
          debugShowCheckedModeBanner: false,
          themeMode: settings.mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            textTheme: _buildCleanTextTheme(Brightness.light),
            colorScheme: ColorScheme.fromSeed(
              seedColor: kToska,
              primary: kToska,
              secondary: kNavyPrimary,
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              foregroundColor: kNavyPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                color: kNavyPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kToska, width: 1.6),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            textTheme: _buildCleanTextTheme(Brightness.dark),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF22B8CF),
              primary: const Color(0xFF22B8CF),
              secondary: const Color(0xFF60A5FA),
              surface: const Color(0xFF111D30),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0C1626).withValues(alpha: 0.88),
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF111D30),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E3250)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E3250)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: Color(0xFF22B8CF), width: 1.6),
              ),
            ),
          ),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(settings.fontScale),
              ),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                  dark ? Brightness.light : Brightness.dark,
                  systemNavigationBarColor:
                  dark ? const Color(0xFF09111E) : const Color(0xFFF1F5F9),
                  systemNavigationBarIconBrightness:
                  dark ? Brightness.light : Brightness.dark,
                ),
                child: SafeArea(
                  top: false,
                  left: true,
                  right: true,
                  bottom: mq.viewPadding.bottom > 0,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: dark
                                  ? const [
                                Color(0xFF09111E),
                                Color(0xFF0E1B2E),
                                Color(0xFF09111E),
                              ]
                                  : const [
                                Color(0xFFF1F5F9),
                                Color(0xFFE5F7F5),
                                Color(0xFFF8FAFC),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -90,
                        right: -70,
                        child: IgnorePointer(
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  kToska.withValues(alpha: dark ? 0.18 : 0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: -80,
                        child: IgnorePointer(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  kNavyPrimary
                                      .withValues(alpha: dark ? 0.22 : 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (child != null) child,
                    ],
                  ),
                ),
              ),
            );
          },
          home: CampusSplashScreen(
            nextScreen: initialTarget,
            autoRedirect: store.isLoggedIn,
          ),
        );
      },
    );
  }
}