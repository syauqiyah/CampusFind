import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard.dart';
import 'core.dart';
import 'guard_screens.dart';
import 'splash_screen.dart';
import 'student_screens.dart';
import 'unesa_logo.dart';
import 'widgets.dart';

const Color _kSlateTitle = Color(0xFF0F172A);
const Color _kSlateBadgeText = Color(0xFF1E293B);
const Color _kEmeraldGreen = Color(0xFF15803D);
const Color _kTealGreen = Color(0xFF0F766E);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Widget? _resolvedNext;
  bool _alreadyLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialScreen();
  }

  Future<void> _resolveInitialScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        try {
          user = await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          user = FirebaseAuth.instance.currentUser;
        }
      }

      if (prefs.getBool('guard_logged_in') == true) {
        final savedId = (prefs.getString('guard_id') ?? '').trim().toUpperCase();
        if (savedId.isNotEmpty) {
          Map<String, dynamic>? data;
          var answered = false;
          try {
            final officerDoc = await FirebaseFirestore.instance
                .collection('satpam_officers')
                .doc(savedId)
                .get()
                .timeout(const Duration(seconds: 6));
            answered = true;
            data = officerDoc.exists ? officerDoc.data() : null;
          } catch (_) {}

          final stillValid = answered ? (data != null && data['active'] == true) : true;
          if (stillValid) {
            if (FirebaseAuth.instance.currentUser != null) {
              await FirebaseAuth.instance.signOut();
            }

            store.guard = true;
            store.email = savedId;
            store.guardPos = (data?['post'] as String?) ?? prefs.getString('guard_pos') ?? posList[0];
            await store.load();
            final officialName = (data?['name'] as String?)?.trim() ?? '';
            if (officialName.isNotEmpty) {
              store.customName = officialName;
            }

            if (!mounted) return;
            setState(() {
              _resolvedNext = const GuardShell();
              _alreadyLoggedIn = true;
            });
            return;
          }
        }
        await prefs.remove('guard_logged_in');
        await prefs.remove('guard_id');
        await prefs.remove('guard_pos');
      }

      if (user != null && user.email != null) {
        final email = user.email!.toLowerCase();
        var role = prefs.getString('user_role') ?? 'student';
        var blocked = false;
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 6));
          final data = doc.data();
          if (data != null) {
            blocked = data['blocked'] == true;
            role = (data['role'] as String?) ?? role;
            await prefs.setString('user_role', role);
          }
        } catch (_) {}

        var unverified = false;
        if (!blocked && role != 'admin') {
          var verified = user.emailVerified;
          if (!verified) {
            try {
              await user.reload();
              verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
            } catch (_) {}
          }
          unverified = !verified;
        }

        if (blocked || unverified) {
          await FirebaseAuth.instance.signOut();
          await prefs.remove('user_role');
        } else {
          store.guard = false;
          store.email = email;
          await store.load();

          if (!mounted) return;
          if (role == 'admin') {
            setState(() {
              _resolvedNext = AdminDashboardScreen(adminEmail: email);
              _alreadyLoggedIn = true;
            });
          } else {
            final seen = prefs.getBool('tutorial_seen') ?? false;
            setState(() {
              _resolvedNext = seen ? const StudentShell() : const TutorialScreen();
              _alreadyLoggedIn = true;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Auto-login check error: $e');
    }

    if (!mounted) return;
    setState(() {
      _resolvedNext = const ChooseLoginScreen();
      _alreadyLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CampusSplashScreen(
      nextScreen: _resolvedNext ?? const ChooseLoginScreen(),
      autoRedirect: _alreadyLoggedIn,
      loadingSession: _resolvedNext == null,
    );
  }
}

class _FlatUnesaPortalBanner extends StatefulWidget {
  final double height;
  final Widget? child;

  const _FlatUnesaPortalBanner({
    this.height = 195,
    this.child,
  });

  @override
  State<_FlatUnesaPortalBanner> createState() => _FlatUnesaPortalBannerState();
}

class _FlatUnesaPortalBannerState extends State<_FlatUnesaPortalBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  bool get _isNightTime {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context) || _isNightTime;

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _FlatUnesaRektoratBannerPainter(
              progress: _ctrl.value,
              isNight: dark,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _FlatUnesaRektoratBannerPainter extends CustomPainter {
  final double progress;
  final bool isNight;

  _FlatUnesaRektoratBannerPainter({
    required this.progress,
    required this.isNight,
  }) : super(repaint: UnesaLogoCache.notifier);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h - 34;
    final cx = w * 0.5;
    final scale = (w / 440.0).clamp(0.76, 1.0);

    final pathTopW = 22.0 * scale;
    final pathBotW = 40.0 * scale;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = isNight
            ? const Color(0xFF0A192F)
            : const Color(0xFF0284C7),
    );

    if (isNight) {
      final starPaint = Paint()..color = const Color(0xFFE2E8F0);
      final stars = [
        Offset(w * 0.12, h * 0.18),
        Offset(w * 0.24, h * 0.30),
        Offset(w * 0.36, h * 0.16),
        Offset(w * 0.65, h * 0.18),
        Offset(w * 0.78, h * 0.28),
        Offset(w * 0.90, h * 0.15),
      ];
      for (final s in stars) {
        canvas.drawCircle(s, 1.3, starPaint);
      }
    }

    final skyBodyCenter = Offset(w * 0.84, h * 0.36);
    if (isNight) {
      canvas.drawCircle(
        skyBodyCenter,
        18,
        Paint()..color = const Color(0xFF152A4A),
      );
      canvas.drawCircle(
        skyBodyCenter,
        11,
        Paint()..color = const Color(0xFFFEF08A),
      );
    } else {
      canvas.drawCircle(
        skyBodyCenter,
        13,
        Paint()..color = const Color(0xFFFACC15),
      );
    }

    final cloudColor =
    isNight ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE);
    final span1 = w + 140;
    final cloud1X = -90 + ((progress * span1) % span1);
    final span2 = w + 120;
    final cloud2X = -70 + (((progress + 0.48) % 1.0) * span2);

    _drawFlatCloud(canvas, Offset(cloud1X, h * 0.25), 0.9, cloudColor);
    _drawFlatCloud(canvas, Offset(cloud2X, h * 0.40), 0.72, cloudColor);

    final hillBack =
    isNight ? const Color(0xFF0A2218) : const Color(0xFF228B3B);
    final grassBase =
    isNight ? const Color(0xFF0D2E20) : const Color(0xFF2E9E44);
    final grassFront =
    isNight ? const Color(0xFF123B29) : const Color(0xFF42B856);
    final bushShadow =
    isNight ? const Color(0xFF071A12) : const Color(0xFF14532D);

    canvas.drawPath(
      Path()
        ..moveTo(0, groundY - 2)
        ..quadraticBezierTo(w * 0.08, groundY - 12, w * 0.18, groundY + 1)
        ..lineTo(w * 0.82, groundY + 1)
        ..quadraticBezierTo(w * 0.92, groundY - 12, w, groundY - 2)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = hillBack,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..color = grassBase,
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, groundY + 12)
        ..quadraticBezierTo(w * 0.22, groundY + 20, cx - pathTopW, groundY + 15)
        ..lineTo(cx - pathBotW, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = grassFront,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, groundY + 10)
        ..quadraticBezierTo(w * 0.78, groundY + 19, cx + pathTopW, groundY + 14)
        ..lineTo(cx + pathBotW, h)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = grassFront,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 124 * scale, groundY + 3),
        width: 78 * scale,
        height: 11 * scale,
      ),
      Paint()..color = bushShadow,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 124 * scale, groundY + 3),
        width: 78 * scale,
        height: 11 * scale,
      ),
      Paint()..color = bushShadow,
    );

    final bladeDarkPaint = Paint()
      ..color = isNight ? const Color(0xFF071A12) : const Color(0xFF14532D)
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bladeLightPaint = Paint()
      ..color = isNight ? const Color(0xFF2E6F52) : const Color(0xFF86EFAC)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (double bx = 8; bx < w - 8; bx += 9.5) {
      if ((bx - cx).abs() < 34 * scale) continue;
      final curveOffset = math.sin((bx / w) * math.pi) * 4.0;
      final by = groundY + 10.0 + curveOffset;
      canvas.drawPath(
        Path()
          ..moveTo(bx - 2.0, by - 4.0)
          ..lineTo(bx - 0.3, by)
          ..lineTo(bx + 2.2, by - 3.8),
        bladeDarkPaint,
      );
    }

    for (double bx = 10; bx < w - 10; bx += 10.5) {
      if ((bx - cx).abs() < 44 * scale) continue;
      final curveOffset = math.sin((bx / w) * math.pi) * 5.0;
      final by = groundY + 25.0 + curveOffset;
      canvas.drawPath(
        Path()
          ..moveTo(bx - 2.2, by - 4.5)
          ..lineTo(bx - 0.2, by)
          ..lineTo(bx + 2.4, by - 4.2),
        bladeLightPaint,
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(cx - pathTopW, groundY)
        ..lineTo(cx + pathTopW, groundY)
        ..lineTo(cx + pathBotW, h)
        ..lineTo(cx - pathBotW, h)
        ..close(),
      Paint()
        ..color = isNight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
    );
    canvas.drawLine(
      Offset(cx - pathTopW, groundY),
      Offset(cx - pathBotW, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.4,
    );
    canvas.drawLine(
      Offset(cx + pathTopW, groundY),
      Offset(cx + pathBotW, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.4,
    );

    canvas.save();
    canvas.translate(cx, groundY);
    canvas.scale(scale, scale);

    final wallWhite = isNight ? const Color(0xFFCBD5E1) : Colors.white;
    final wallShadow = isNight ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0);
    final glassBlue = isNight ? const Color(0xFF1D4ED8) : const Color(0xFF0284C7);
    final glassDeep = isNight ? const Color(0xFF1E3A8A) : const Color(0xFF0369A1);
    const navyBox = Color(0xFF0B357A);
    const roofBrown = Color(0xFF5C4033);
    const roofLine = Color(0xFF3E2723);

    for (final dir in [-1.0, 1.0]) {
      canvas.save();
      if (dir < 0) canvas.scale(-1, 1);

      const wx = 44.0;
      const ww = 92.0;
      const wh = 68.0;

      canvas.drawRect(
        const Rect.fromLTWH(wx, -wh, ww, wh),
        Paint()..color = wallWhite,
      );

      canvas.drawPath(
        Path()
          ..moveTo(wx - 3, -wh)
          ..lineTo(wx + ww * 0.48, -wh - 12)
          ..lineTo(wx + ww + 3, -wh)
          ..close(),
        Paint()..color = roofBrown,
      );
      canvas.drawLine(
        Offset(wx - 3, -wh),
        Offset(wx + ww + 3, -wh),
        Paint()
          ..color = wallWhite
          ..strokeWidth = 2.0,
      );

      canvas.drawRect(
        const Rect.fromLTWH(wx, -wh + 2, ww - 8, 22),
        Paint()..color = glassBlue,
      );
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 0.8;
      canvas.drawLine(
          const Offset(wx, -wh + 13), const Offset(wx + ww - 8, -wh + 13), gridPaint);
      for (double gx = wx + 14; gx < wx + ww - 8; gx += 14) {
        canvas.drawLine(Offset(gx, -wh + 2), Offset(gx, -wh + 24), gridPaint);
      }

      canvas.drawRect(
        const Rect.fromLTWH(wx, -44, ww - 14, 44),
        Paint()..color = glassDeep,
      );
      canvas.drawRect(
        const Rect.fromLTWH(wx + 6, -16, 46, 5),
        Paint()..color = wallWhite,
      );
      for (var p = 0; p < 4; p++) {
        final px = wx + 8.0 + p * 14.0;
        canvas.drawRect(
          Rect.fromLTWH(px, -44, 6.5, 44),
          Paint()..color = wallWhite,
        );
      }

      canvas.drawRect(
        const Rect.fromLTWH(wx + ww - 14, -44, 14, 44),
        Paint()..color = wallShadow,
      );
      canvas.drawRect(
        const Rect.fromLTWH(wx + 2, -6, ww - 4, 6),
        Paint()
          ..color = isNight ? const Color(0xFF14532D) : const Color(0xFF15803D),
      );

      canvas.restore();
    }

    const tw = 88.0;
    const th = 114.0;

    canvas.drawRect(
      const Rect.fromLTWH(-tw / 2, -th, tw, th),
      Paint()..color = wallWhite,
    );

    canvas.drawPath(
      Path()
        ..moveTo(-tw / 2 - 5, -th)
        ..lineTo(0, -th - 15)
        ..lineTo(tw / 2 + 5, -th)
        ..close(),
      Paint()..color = roofBrown,
    );
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(
        const Offset(0, -th - 15),
        Offset(i * 13.0, -th),
        Paint()
          ..color = roofLine.withValues(alpha: 0.45)
          ..strokeWidth = 0.8,
      );
    }
    canvas.drawRect(
      const Rect.fromLTWH(-tw / 2 - 5, -th, tw + 10, 3.5),
      Paint()..color = wallWhite,
    );

    canvas.drawRect(
      const Rect.fromLTWH(-28, -th + 4, 56, th - 22),
      Paint()..color = glassBlue,
    );
    for (double ky = -th + 16; ky < -20; ky += 11) {
      canvas.drawLine(
        Offset(-28, ky),
        Offset(28, ky),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 0.8,
      );
    }

    canvas.drawRect(
      const Rect.fromLTWH(-7, -78, 14, 60),
      Paint()..color = wallWhite,
    );
    for (var wRow = 0; wRow < 6; wRow++) {
      canvas.drawRect(
        Rect.fromLTWH(-3.5, -75 + wRow * 9.5, 7, 6),
        Paint()
          ..color = isNight ? const Color(0xFFFDE047) : navyBox,
      );
    }

    for (var row = 0; row < 10; row++) {
      final wy = -th + 8.0 + row * 9.2;
      final winColor = isNight ? const Color(0xFFFDE047) : navyBox;
      canvas.drawRect(
        Rect.fromLTWH(-tw / 2 + 5, wy, 5.5, 5.5),
        Paint()..color = winColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(tw / 2 - 10.5, wy, 5.5, 5.5),
        Paint()..color = winColor,
      );
    }

    canvas.drawRect(
      const Rect.fromLTWH(-14, -th + 6, 28, 30),
      Paint()..color = wallWhite,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-12.2, -th + 7.8, 24.4, 26.4),
      Paint()..color = navyBox,
    );
    drawUnesaBadge(canvas, const Offset(0, -th + 21), 10.5);

    canvas.drawRect(
      const Rect.fromLTWH(-28, -24, 9, 24),
      Paint()..color = const Color(0xFFDC2626),
    );
    canvas.drawRect(
      const Rect.fromLTWH(19, -24, 9, 24),
      Paint()..color = const Color(0xFFDC2626),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-19, -20, 38, 20),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-12, -16, 24, 4),
      Paint()..color = const Color(0xFFEF4444),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-31, -18, 62, 4),
      Paint()..color = wallWhite,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-34, -5, 68, 5),
      Paint()..color = wallShadow,
    );

    _drawDetailedTree(canvas, -138, 4, 1.02);
    _drawDetailedTree(canvas, -110, 4, 0.86);
    _drawDetailedTree(canvas, 110, 4, 0.86);
    _drawDetailedTree(canvas, 138, 4, 1.02);

    const poleTop = -84.0;
    const poleBot = 6.0;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, poleBot), width: 22, height: 6),
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      const Offset(0, poleTop),
      const Offset(0, poleBot),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(0, poleTop - 1),
      2.5,
      Paint()..color = const Color(0xFFF59E0B),
    );

    final wind = progress * math.pi * 24;
    const flagW = 24.0;
    const flagH = 14.0;
    const flagY = poleTop + 2.5;

    Path flagBand(double y0, double bh) {
      final p = Path()..moveTo(0, y0);
      const steps = 10;
      for (var i = 1; i <= steps; i++) {
        final r = i / steps;
        final x = flagW * r;
        final wv = math.sin(wind - r * 4.2) * 1.8 * r;
        p.lineTo(x, y0 + wv);
      }
      for (var i = steps; i >= 0; i--) {
        final r = i / steps;
        final x = flagW * r;
        final wv = math.sin(wind - r * 4.2) * 1.8 * r;
        p.lineTo(x, y0 + bh + wv);
      }
      p.close();
      return p;
    }

    canvas.drawPath(
      flagBand(flagY, flagH / 2),
      Paint()..color = const Color(0xFFDC2626),
    );
    canvas.drawPath(
      flagBand(flagY + flagH / 2, flagH / 2),
      Paint()..color = Colors.white,
    );

    canvas.restore();

    if (isNight) {
      final t = progress * 45.0;
      final bugs = [
        (0.14, 0.38, 0.2),
        (0.26, 0.65, 1.5),
        (0.72, 0.44, 2.8),
        (0.86, 0.68, 4.1),
        (0.18, 0.86, 5.2),
        (0.78, 0.85, 3.6),
      ];
      for (final b in bugs) {
        final blink = 0.5 + 0.5 * math.sin(t * 2.5 + b.$3);
        final pos = Offset(
          w * b.$1 + math.sin(t + b.$3) * 7,
          h * b.$2 + math.cos(t * 0.9 + b.$3) * 5,
        );
        canvas.drawCircle(
          pos,
          1.2 + blink * 1.1,
          Paint()..color = const Color(0xFFFDE047),
        );
      }
    }
  }

  void _drawFlatCloud(Canvas canvas, Offset pos, double s, Color color) {
    final p = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx, pos.dy + 8 * s, 54 * s, 14 * s),
        Radius.circular(10 * s),
      ),
      p,
    );
    canvas.drawCircle(Offset(pos.dx + 18 * s, pos.dy + 9 * s), 10 * s, p);
    canvas.drawCircle(Offset(pos.dx + 33 * s, pos.dy + 7 * s), 12 * s, p);
  }

  void _drawDetailedTree(Canvas canvas, double x, double groundY, double s) {
    final trunkColor =
    isNight ? const Color(0xFF3E2723) : const Color(0xFF5D4037);
    final trunkHighlight =
    isNight ? const Color(0xFF4E342E) : const Color(0xFF8D6E63);
    final leafDark =
    isNight ? const Color(0xFF062E1D) : const Color(0xFF14532D);
    final leafMid =
    isNight ? const Color(0xFF0E4D31) : const Color(0xFF15803D);
    final leafBright =
    isNight ? const Color(0xFF1B7A4E) : const Color(0xFF4ADE80);
    final twigColor =
    isNight ? const Color(0xFF041C11) : const Color(0xFF0B3B1E);

    final trunkPath = Path()
      ..moveTo(x - 3.2 * s, groundY + 1)
      ..quadraticBezierTo(
          x - 1.6 * s, groundY - 14 * s, x - 1.4 * s, groundY - 26 * s)
      ..lineTo(x - 11 * s, groundY - 37 * s)
      ..lineTo(x - 9.5 * s, groundY - 38 * s)
      ..lineTo(x - 0.5 * s, groundY - 28 * s)
      ..lineTo(x - 0.3 * s, groundY - 41 * s)
      ..lineTo(x + 1.3 * s, groundY - 41 * s)
      ..lineTo(x + 1.2 * s, groundY - 27 * s)
      ..lineTo(x + 11.5 * s, groundY - 36 * s)
      ..lineTo(x + 12.5 * s, groundY - 34.5 * s)
      ..lineTo(x + 1.8 * s, groundY - 24 * s)
      ..quadraticBezierTo(
          x + 1.8 * s, groundY - 13 * s, x + 3.5 * s, groundY + 1)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = trunkColor);

    canvas.drawPath(
      Path()
        ..moveTo(x - 1.2 * s, groundY)
        ..quadraticBezierTo(
            x - 0.6 * s, groundY - 14 * s, x - 0.4 * s, groundY - 26 * s),
      Paint()
        ..color = trunkHighlight
        ..strokeWidth = 1.0 * s
        ..style = PaintingStyle.stroke,
    );

    Path organicCluster(
        double cx, double cy, double rx, double ry, double seed) {
      final p = Path();
      const lobes = 11;
      for (var i = 0; i <= lobes; i++) {
        final a = (i / lobes) * math.pi * 2;
        final wobble = 0.82 +
            0.24 * math.sin(a * 3 + seed) +
            0.14 * math.cos(a * 5 - seed);
        final px = cx + math.cos(a) * rx * wobble;
        final py = cy + math.sin(a) * ry * wobble;
        if (i == 0) {
          p.moveTo(px, py);
        } else {
          final prevA = ((i - 0.5) / lobes) * math.pi * 2;
          final cWobble = 1.06 + 0.20 * math.sin(prevA * 4 + seed);
          final cpx = cx + math.cos(prevA) * rx * cWobble;
          final cpy = cy + math.sin(prevA) * ry * cWobble;
          p.quadraticBezierTo(cpx, cpy, px, py);
        }
      }
      p.close();
      return p;
    }

    canvas.drawPath(
      organicCluster(x - 12 * s, groundY - 37 * s, 12.5 * s, 9.5 * s, 0.4),
      Paint()..color = leafDark,
    );
    canvas.drawPath(
      organicCluster(x + 12 * s, groundY - 36 * s, 12.0 * s, 9.0 * s, 1.9),
      Paint()..color = leafDark,
    );
    canvas.drawPath(
      organicCluster(x, groundY - 40 * s, 15.0 * s, 11.5 * s, 3.1),
      Paint()..color = leafDark,
    );

    canvas.drawPath(
      organicCluster(x - 11 * s, groundY - 41 * s, 11.0 * s, 8.5 * s, 1.1),
      Paint()..color = leafMid,
    );
    canvas.drawPath(
      organicCluster(x + 11 * s, groundY - 40 * s, 10.5 * s, 8.0 * s, 2.6),
      Paint()..color = leafMid,
    );
    canvas.drawPath(
      organicCluster(x - 1 * s, groundY - 46 * s, 13.5 * s, 10.0 * s, 4.2),
      Paint()..color = leafMid,
    );

    canvas.drawPath(
      organicCluster(x - 8 * s, groundY - 47 * s, 8.5 * s, 6.2 * s, 0.8),
      Paint()..color = leafBright,
    );
    canvas.drawPath(
      organicCluster(x + 2 * s, groundY - 51 * s, 9.5 * s, 6.8 * s, 2.3),
      Paint()..color = leafBright,
    );
    canvas.drawPath(
      organicCluster(x + 10 * s, groundY - 44 * s, 7.5 * s, 5.5 * s, 3.9),
      Paint()..color = leafBright,
    );

    final detailPaint = Paint()
      ..color = twigColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.05 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(x - 14 * s, groundY - 39 * s)
        ..quadraticBezierTo(
            x - 9 * s, groundY - 43 * s, x - 5 * s, groundY - 40 * s)
        ..moveTo(x - 4 * s, groundY - 47 * s)
        ..quadraticBezierTo(
            x + 1 * s, groundY - 50 * s, x + 6 * s, groundY - 46 * s)
        ..moveTo(x + 4 * s, groundY - 38 * s)
        ..quadraticBezierTo(
            x + 9 * s, groundY - 41 * s, x + 14 * s, groundY - 37 * s)
        ..moveTo(x - 7 * s, groundY - 33 * s)
        ..quadraticBezierTo(
            x - 1 * s, groundY - 36 * s, x + 5 * s, groundY - 33 * s),
      detailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlatUnesaRektoratBannerPainter old) =>
      old.progress != progress || old.isNight != isNight;
}

class AuthScaffold extends StatelessWidget {
  final String badgeText;
  final String title;
  final String subtitle;
  final double maxWidth;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    this.maxWidth = 480,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final subColor = dark ? Colors.white70 : const Color(0xFF475569);
    final screenW = MediaQuery.of(context).size.width;
    final titleFontSize = (screenW * 0.068).clamp(22.0, 28.0);

    return Scaffold(
      body: Column(
        children: [
          _FlatUnesaPortalBanner(
            height: 195,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Navigator.canPop(context))
                      TapScale(
                        onTap: () => Navigator.pop(context),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: dark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            foregroundColor:
                            dark ? Colors.white : _kSlateTitle,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: dark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _kEmeraldGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'UNESA LOST & FOUND PORTAL',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: dark ? Colors.white : _kSlateBadgeText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        index: 0,
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.85, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutBack,
                              builder: (_, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const AppLogo(size: 60),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: dark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                badgeText.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: dark
                                      ? const Color(0xFFE2E8F0)
                                      : _kSlateBadgeText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w900,
                                  color: dark ? Colors.white : _kSlateTitle,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: Text(
                                subtitle,
                                key: ValueKey(subtitle),
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: subColor,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChooseLoginScreen extends StatelessWidget {
  const ChooseLoginScreen({super.key});

  Widget _roleCard({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String roleTag,
    required String title,
    required String sub,
    required String btnLabel,
    required bool guard,
    required Color accent,
  }) {
    final dark = isDark(context);

    return FadeSlideIn(
      index: index,
      child: InteractiveCard(
        accentColor: accent,
        onTap: () =>
            Navigator.push(context, smoothRoute(LoginScreen(guard: guard))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 25),
                ),
                Flexible(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      roleTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: dark ? const Color(0xFFE2E8F0) : _kSlateBadgeText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: mutedC(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              decoration: BoxDecoration(
                color: guard
                    ? (dark
                    ? const Color(0xFF134E4A)
                    : const Color(0xFFDCFCE7))
                    : (dark ? const Color(0xFF16A34A) : _kEmeraldGreen),
                borderRadius: BorderRadius.circular(14),
                border: guard
                    ? Border.all(
                  color: dark
                      ? const Color(0xFF2DD4BF)
                      : const Color(0xFF86EFAC),
                  width: 1.3,
                )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      btnLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: guard
                            ? (dark ? Colors.white : _kTealGreen)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: guard
                        ? (dark ? Colors.white : _kTealGreen)
                        : Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return AuthScaffold(
      badgeText: 'Pusat Barang Hilang & Temuan',
      title: 'Temukan Kembali\nBarang Berhargamu',
      subtitle:
      'Sistem pelaporan barang hilang & temuan mahasiswa dengan verifikasi pos satpam UNESA.',
      maxWidth: isWide ? 840 : 480,
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _roleCard(
                  context: context,
                  index: 1,
                  icon: Icons.school_rounded,
                  roleTag: 'MAHASISWA UNESA',
                  title: 'Login Mahasiswa UNESA',
                  sub:
                  'Khusus mahasiswa UNESA dengan email resmi @mhs.unesa.ac.id untuk melapor & mengklaim barang.',
                  btnLabel: 'Masuk Mahasiswa UNESA',
                  guard: false,
                  accent: _kEmeraldGreen,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _roleCard(
                  context: context,
                  index: 2,
                  icon: Icons.verified_user_rounded,
                  roleTag: 'SATPAM UNESA',
                  title: 'Login Satpam Pos UNESA',
                  sub:
                  'Petugas satpam pos gerbang UNESA untuk verifikasi laporan, QR Pos, dan serah terima barang.',
                  btnLabel: 'Masuk sebagai Satpam',
                  guard: true,
                  accent: _kTealGreen,
                ),
              ),
            ],
          )
        else ...[
          _roleCard(
            context: context,
            index: 1,
            icon: Icons.school_rounded,
            roleTag: 'MAHASISWA UNESA',
            title: 'Login Mahasiswa UNESA',
            sub:
            'Khusus mahasiswa UNESA dengan email resmi @mhs.unesa.ac.id untuk melapor & mengklaim barang.',
            btnLabel: 'Masuk Mahasiswa UNESA',
            guard: false,
            accent: _kEmeraldGreen,
          ),
          const SizedBox(height: 16),
          _roleCard(
            context: context,
            index: 2,
            icon: Icons.verified_user_rounded,
            roleTag: 'SATPAM UNESA',
            title: 'Login Satpam Pos UNESA',
            sub:
            'Petugas satpam pos gerbang UNESA untuk verifikasi laporan, QR Pos, dan serah terima barang.',
            btnLabel: 'Masuk sebagai Satpam',
            guard: true,
            accent: _kTealGreen,
          ),
        ],
      ],
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool guard;
  const LoginScreen({super.key, required this.guard});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final idC = TextEditingController();
  final passC = TextEditingController();
  bool hide = true;
  bool loading = false;
  String? pos;

  static const _defaultGuardPassword = 'satpam123';

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final email = googleUser.email.trim().toLowerCase();

      if (!email.endsWith('@mhs.unesa.ac.id')) {
        await googleSignIn.signOut();
        if (mounted) {
          setState(() => loading = false);
          _showError('Wajib menggunakan akun Google resmi mahasiswa UNESA (@mhs.unesa.ac.id).');
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final uid = firebaseUser.uid;
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(uid);
      final doc = await userRef.get();

      if (doc.exists && doc.data()?['blocked'] == true) {
        await FirebaseAuth.instance.signOut();
        await googleSignIn.signOut();
        if (mounted) {
          setState(() => loading = false);
          _showError('Akun Anda dibekukan sementara oleh Admin Supervisor.');
        }
        return;
      }

      String nim = '';
      final usernamePart = email.split('@').first;
      if (RegExp(r'^\d+$').hasMatch(usernamePart)) {
        nim = usernamePart;
      }

      final photoUrl = googleUser.photoUrl ?? firebaseUser.photoURL ?? '';
      String displayName = googleUser.displayName?.trim() ?? firebaseUser.displayName?.trim() ?? '';
      if (displayName.isEmpty) {
        displayName = usernamePart;
      }

      String role = 'student';
      if (!doc.exists) {
        await userRef.set({
          'email': email,
          'name': displayName,
          'nim': nim,
          'role': 'student',
          'blocked': false,
          'photoUrl': photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final userData = doc.data();
        role = (userData?['role'] as String?) ?? 'student';
        final savedName = (userData?['name'] as String?) ?? '';
        if (savedName.isNotEmpty) displayName = savedName;
        final savedNim = (userData?['nim'] as String?) ?? '';
        if (savedNim.isNotEmpty) nim = savedNim;
        if (photoUrl.isNotEmpty) {
          await userRef.set({'photoUrl': photoUrl}, SetOptions(merge: true));
        }
      }

      final finalPhotoUrl = photoUrl.isNotEmpty ? photoUrl : (doc.data()?['photoUrl'] as String? ?? '');

      store.guard = false;
      store.email = email;
      await store.login(
        uid: uid,
        name: displayName,
        email: email,
        nim: nim,
        role: role,
        photoUrl: finalPhotoUrl,
      );
      await store.load();

      if (!mounted) return;
      final nav = Navigator.of(context);

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (role == 'admin') {
        nav.pushAndRemoveUntil(
          smoothRoute(AdminDashboardScreen(adminEmail: email)),
              (r) => false,
        );
      } else {
        final seen = prefs.getBool('tutorial_seen') ?? false;
        final Widget next = seen ? const StudentShell() : const TutorialScreen();
        nav.pushAndRemoveUntil(smoothRoute(next), (r) => false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal masuk dengan Google: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final db = FirebaseFirestore.instance;

      if (widget.guard) {
        final rawId = idC.text.trim();
        final inputPass = passC.text.trim();

        if (rawId.contains('@')) {
          _showError('Akses ditolak! Email Mahasiswa/Admin tidak dapat masuk ke Portal Satpam.');
          return;
        }

        final guardId = rawId.toUpperCase();
        final officerDoc = await db.collection('satpam_officers').doc(guardId).get();

        if (!officerDoc.exists || officerDoc.data() == null) {
          _showError('ID Petugas "$guardId" tidak terdaftar! Hubungi Admin Supervisor untuk pendaftaran ID resmi.');
          return;
        }

        final data = officerDoc.data()!;
        if (data['active'] != true) {
          _showError('Akun petugas "$guardId" sedang dinonaktifkan oleh Admin Supervisor.');
          return;
        }

        final customDocPass = (data['pin'] ?? data['password'] ?? '').toString().trim();
        final expectedPass = customDocPass.isNotEmpty ? customDocPass : _defaultGuardPassword;
        if (inputPass != expectedPass) {
          _showError('Password Satpam salah! Pastikan Anda memasukkan password petugas yang benar.');
          return;
        }

        final registeredPos = (data['post'] as String?) ?? '';
        if (registeredPos.isNotEmpty && registeredPos != pos) {
          _showError('ID "$guardId" hanya terdaftar untuk bertugas di $registeredPos, bukan di $pos.');
          return;
        }

        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }

        final officialName = (data['name'] as String?)?.trim() ?? '';
        store.guard = true;
        store.email = guardId;
        store.guardPos = pos!;
        if (officialName.isNotEmpty) {
          store.customName = officialName;
        }

        await prefs.remove('user_role');
        await prefs.setBool('guard_logged_in', true);
        await prefs.setString('guard_id', guardId);
        await prefs.setString('guard_pos', pos!);
        await store.load();
        if (officialName.isNotEmpty) {
          store.customName = officialName;
        }

        final seen = prefs.getBool('guard_tutorial_seen') ?? false;
        if (!mounted) return;
        final Widget next = seen ? const GuardShell() : const TutorialScreen();
        Navigator.pushAndRemoveUntil(context, smoothRoute(next), (r) => false);
        return;
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guard;
    final dark = isDark(context);

    if (!g) {
      return AuthScaffold(
        badgeText: 'Autentikasi Mahasiswa',
        title: 'Login Mahasiswa UNESA',
        subtitle: 'Akses khusus mahasiswa UNESA menggunakan akun Google resmi (@mhs.unesa.ac.id).',
        maxWidth: 460,
        children: [
          FadeSlideIn(
            index: 1,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardC(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderC(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.25 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.65)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: _kSlateBadgeText,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Akun Mahasiswa UNESA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: dark ? Colors.white : _kSlateTitle,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Gunakan email SSO Google mahasiswa (@mhs.unesa.ac.id).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedC(context),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: loading
                        ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: _kEmeraldGreen)),
                    )
                        : SizedBox(
                      key: const ValueKey('btn_google_login'),
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login_rounded, size: 19),
                        label: const Text(
                          'Masuk dengan Google',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dark
                              ? const Color(0xFF16A34A)
                              : _kEmeraldGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AuthScaffold(
      badgeText: 'Akses Satpam UNESA',
      title: 'Portal Satpam Pos UNESA',
      subtitle: 'Masukkan ID Petugas resmi, password petugas, dan pilih lokasi pos penjagaan Anda.',
      maxWidth: 460,
      children: [
        FadeSlideIn(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardC(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderC(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.25 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppField(
                    'ID Petugas Resmi',
                    'Contoh: SATPAM01',
                    controller: idC,
                    icon: Icons.badge_outlined,
                    keyboard: TextInputType.text,
                    helper: 'ID Petugas diterbitkan oleh Admin Supervisor (bukan email mahasiswa)',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      if (v.trim().contains('@')) {
                        return 'Gunakan ID Petugas resmi, bukan email mahasiswa';
                      }
                      return null;
                    },
                  ),
                  const Text('Password Petugas',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: passC,
                    obscureText: hide,
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password petugas pos',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(hide ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: () => setState(() => hide = !hide),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppDropdown(
                    'Bertugas di',
                    'Pilih pos satpam',
                    posList,
                    pos,
                        (v) => setState(() => pos = v),
                    isRequired: true,
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: loading
                        ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: _kTealGreen)),
                    )
                        : SizedBox(
                      key: const ValueKey('btn_satpam_login'),
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _login,
                        icon: const Icon(Icons.verified_user_rounded,
                            size: 19),
                        label: const Text(
                          'Masuk ke Pos',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dark
                              ? const Color(0xFF0D9488)
                              : _kTealGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- tutorial
class TutorialScreen extends StatefulWidget {
  final bool fromProfile;
  const TutorialScreen({super.key, this.fromProfile = false});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final pc = PageController();
  int page = 0;

  static const studentPages = [
    (Icons.mark_email_read_rounded, 'Masuk dengan Email Mahasiswa', 'Login memakai email resmi mahasiswa UNESA (@mhs.unesa.ac.id) untuk menggunakan aplikasi.'),
    (Icons.edit_note_rounded, 'Buat Laporan', 'Di menu Laporan pilih Lapor Kehilangan atau Lapor Barang Ditemukan. Upload foto barang, AI akan mengenali nama, jenis, warna, dan ciri-ciri. Lalu pilih pos satpam (Gerbang Depan / Belakang).'),
    (Icons.qr_code_2_rounded, 'Verifikasi QR Satpam', 'Buka laporan yang tersimpan kapan saja untuk memindai QR pos satpam. Setelah disetujui, laporanmu tampil di Beranda.'),
    (Icons.auto_awesome_rounded, 'Notifikasi Pencocokan', 'Setelah laporan hilangmu disetujui, sistem mencocokkan otomatis dengan barang temuan. Notifikasi berbunyi dan menampilkan barang yang paling mirip beserta persentase kecocokan.'),
    (Icons.verified_rounded, 'Klaim Barang', 'Buka barang temuan di Beranda atau Cari, lalu Ajukan Klaim dan sebutkan detail rahasianya. Pindai QR pos satpam saat verifikasi. Jika cocok dan disetujui, barang diserahkan kepadamu.'),
  ];

  static const guardPages = [
    (Icons.dashboard_customize_rounded, 'Menu Beranda Satpam', 'Di menu Beranda, pantau antrean verifikasi laporan barang masuk dan daftar klaim mahasiswa yang menunggu tindakan di pos jaga Anda.'),
    (Icons.qr_code_scanner_rounded, 'QR Barcode Pos Satpam', 'Gunakan menu QR Pos untuk menampilkan kode QR dinamis pos jaga agar dipindai mahasiswa saat menyerahkan barang temuan atau mengambil barang klaim.'),
    (Icons.fact_check_rounded, 'Verifikasi Detail Rahasia', 'Saat meninjau klaim, aplikasi menampilkan kotak perbandingan antara ciri barang pada laporan dengan jawaban pengklaim secara berdampingan.'),
    (Icons.task_alt_rounded, 'Keputusan & Serah Terima', 'Tekan tombol hijau "Setujui Klaim & Serahkan Barang" jika data cocok, atau tombol bergaris "Tolak Klaim" jika data tidak sesuai.'),
    (Icons.filter_list_rounded, 'Filter di Menu Laporan', 'Buka menu Laporan untuk melihat seluruh arsip. Gunakan chip filter status dan filter pos di bagian atas untuk menyortir data.'),
  ];

  Future<void> _finish() async {
    if (widget.fromProfile) {
      Navigator.pop(context);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = store.guard ? 'guard_tutorial_seen' : 'tutorial_seen';
    await prefs.setBool(key, true);
    if (!mounted) return;
    final Widget destination = store.guard ? const GuardShell() : const StudentShell();
    Navigator.pushAndRemoveUntil(context, smoothRoute(destination), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = store.guard ? guardPages : studentPages;
    final last = page == pages.length - 1;
    final dark = isDark(context);

    return PopScope(
      canPop: widget.fromProfile && page == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (page > 0) {
          pc.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutQuart);
        } else {
          _finish();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(store.guard ? 'Tutorial Aplikasi Satpam' : 'Tutorial Penggunaan', style: const TextStyle(fontSize: 16)),
          actions: [if (!last) TextButton(onPressed: _finish, child: const Text('Lewati'))],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                Expanded(
                  child: PageView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: pc,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => page = i),
                    itemBuilder: (_, i) => AnimatedBuilder(
                      animation: pc,
                      builder: (context, child) {
                        double scale = 1.0;
                        if (pc.position.haveDimensions) {
                          final diff = ((pc.page ?? page.toDouble()) - i).abs();
                          scale = (1 - (diff * 0.14)).clamp(0.86, 1.0);
                        }
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: _kSlateBadgeText.withValues(alpha: 0.10),
                            child: Icon(
                              pages[i].$1,
                              size: 54,
                              color: dark ? const Color(0xFFE2E8F0) : _kSlateBadgeText,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(pages[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Text(pages[i].$3, textAlign: TextAlign.center, style: TextStyle(color: mutedC(context), height: 1.55, fontSize: 13.5)),
                        ]),
                      ),
                    ),
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.all(4),
                      width: i == page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == page
                            ? (dark ? const Color(0xFFE2E8F0) : _kSlateBadgeText)
                            : borderC(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ]),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (last) {
                          _finish();
                        } else {
                          pc.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutQuart);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        dark ? const Color(0xFF16A34A) : _kEmeraldGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        last
                            ? (widget.fromProfile
                            ? 'Selesai'
                            : 'Mulai Gunakan')
                            : 'Lanjut',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}