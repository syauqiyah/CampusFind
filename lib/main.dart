import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_screens.dart';
import 'core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'unesa_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await settings.load();
  await UnesaLogoCache.ensureLoaded();

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

class CampusFindApp extends StatelessWidget {
  const CampusFindApp({super.key});

  @override
  Widget build(BuildContext context) {
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
            colorScheme: ColorScheme.fromSeed(
              seedColor: kGreen,
              primary: kGreen,
              secondary: kDeep,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white.withValues(alpha: 0.78),
              foregroundColor: kDeep,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                color: kDeep,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.84),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: kGreen.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: kGreen.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kGreen, width: 1.6),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kGreen,
              primary: kGreen,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0F1E17).withValues(alpha: 0.78),
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF152D22).withValues(alpha: 0.75),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: const Color(0xFF34D399).withValues(alpha: 0.24)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: const Color(0xFF34D399).withValues(alpha: 0.24)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kGreen, width: 1.6),
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
                  statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
                  systemNavigationBarColor: dark ? const Color(0xFF07130D) : const Color(0xFFEFF8F3),
                  systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
                ),
                child: SafeArea(
                  top: false,
                  left: true,
                  right: true,
                  bottom: mq.viewPadding.bottom > 0,
                  child: Stack(
                    children: [
                      // Latar gradien zamrud lembut agar efek Tinted Emerald Glass terlihat hidup
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: dark
                                  ? const [Color(0xFF06100B), Color(0xFF0D2319), Color(0xFF07130D)]
                                  : const [Color(0xFFEFF8F3), Color(0xFFDCF2E6), Color(0xFFF5FBF8)],
                            ),
                          ),
                        ),
                      ),
                      // Pendar cahaya zamrud di sudut kanan atas & kiri bawah
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
                                  kGreen.withValues(alpha: dark ? 0.22 : 0.16),
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
                                  const Color(0xFF34D399).withValues(alpha: dark ? 0.16 : 0.14),
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
          home: const CampusSplashScreen(
            nextScreen: ChooseLoginScreen(),
          ),
        );
      },
    );
  }
}