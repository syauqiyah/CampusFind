import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screens.dart';
import 'unesa_logo.dart';

typedef AuthChoiceScreen = ChooseLoginScreen;

enum _DayPhase { morningDay, sunset, night }

class CampusSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final bool autoRedirect;
  final bool loadingSession;

  const CampusSplashScreen({
    super.key,
    required this.nextScreen,
    this.autoRedirect = false,
    this.loadingSession = false,
  });

  @override
  State<CampusSplashScreen> createState() => _CampusSplashScreenState();
}

class _CampusSplashScreenState extends State<CampusSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _loopCtrl;
  bool _starting = false;
  bool _autoScheduled = false;

  _DayPhase get _dayPhase {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 16) return _DayPhase.morningDay;
    if (hour >= 16 && hour < 18) return _DayPhase.sunset;
    return _DayPhase.night;
  }

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 65),
    )..repeat();

    _checkAutoRedirect();
  }

  @override
  void didUpdateWidget(covariant CampusSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoRedirect && !_autoScheduled) {
      _checkAutoRedirect();
    }
  }

  void _checkAutoRedirect() {
    if (!widget.autoRedirect || _autoScheduled) return;
    _autoScheduled = true;
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _onStartPressed();
    });
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _loopCtrl.dispose();
    super.dispose();
  }

  void _replayIntro() {
    if (_starting) return;
    _introCtrl.reset();
    _introCtrl.forward();
  }

  Future<void> _onStartPressed() async {
    if (_starting || !mounted) return;
    setState(() => _starting = true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  double _seg(double start, double end) {
    final t = _introCtrl.value;
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return Curves.easeOutCubic
        .transform((t - start) / (end - start))
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    String? brandFont;
    try {
      brandFont = GoogleFonts.syne().fontFamily;
    } catch (_) {}

    final phase = _dayPhase;
    final isNight = phase == _DayPhase.night;
    final isSunset = phase == _DayPhase.sunset;

    final titleAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic),
    );
    final btnAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );

    final screenW = MediaQuery.of(context).size.width;

    Color skySolidColor;
    switch (phase) {
      case _DayPhase.morningDay:
        skySolidColor = const Color(0xFF0284C7);
        break;
      case _DayPhase.sunset:
        skySolidColor = const Color(0xFFEA580C);
        break;
      case _DayPhase.night:
        skySolidColor = const Color(0xFF0A192F);
        break;
    }

    return Scaffold(
      backgroundColor: skySolidColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_introCtrl, _loopCtrl]),
        builder: (context, _) {
          final buildingT = _seg(0.00, 0.30);
          final flagT = _seg(0.20, 0.48);
          final logoT = _seg(0.34, 0.68);

          final span1 = screenW + 180.0;
          final cloud1X = -160.0 + ((_loopCtrl.value * span1) % span1);

          final span2 = screenW + 160.0;
          final cloud2X = -140.0 + (((_loopCtrl.value + 0.50) % 1.0) * span2);

          final windPhase = _loopCtrl.value * math.pi * 18;
          final floatY = math.sin(_loopCtrl.value * math.pi * 4) * 3.5;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Latar langit solid
              Container(color: skySolidColor),

              if (isNight)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _NightStarsPainter(),
                  ),
                ),

              // Awan solid berjalan
              Positioned(
                top: 48,
                left: cloud1X,
                child: IgnorePointer(
                  child: _SolidCloud(scale: 1.0, phase: phase),
                ),
              ),
              Positioned(
                top: 94,
                left: cloud2X,
                child: IgnorePointer(
                  child: _SolidCloud(scale: 0.78, phase: phase),
                ),
              ),

              // Matahari / Bulan bundar solid
              Positioned(
                bottom: isSunset ? 150 : 160,
                right: isNight ? 32 : 44,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: buildingT,
                    child: _SkyBody(phase: phase),
                  ),
                ),
              ),

              // Gedung Rektorat UNESA + Rumput & Pohon Organik
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 185,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: buildingT,
                    child: Transform.translate(
                      offset: Offset(0, (1.0 - buildingT) * 55),
                      child: CustomPaint(
                        painter: _UnesaRektoratScenePainter(
                          flagProgress: flagT,
                          windPhase: windPhase,
                          isNight: isNight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Kunang-kunang di seluruh layar saat malam hari
              if (isNight)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _FullScreenFirefliesPainter(
                        time: _loopCtrl.value * 65.0,
                      ),
                    ),
                  ),
                ),

              // Konten utama pas di tengah area langit di atas gedung
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isNight
                            ? const Color(0xFF132A4A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isNight
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF15803D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'UNIVERSITAS NEGERI SURABAYA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isNight
                                  ? Colors.white
                                  : const Color(0xFF0B357A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Logo
                    GestureDetector(
                      onTap: _replayIntro,
                      child: Opacity(
                        opacity: logoT,
                        child: Transform.scale(
                          scale: 0.72 + (logoT * 0.28),
                          child: Transform.translate(
                            offset: Offset(0, floatY),
                            child: Container(
                              width: 142,
                              height: 142,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFBAE6FD),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: CustomPaint(
                                  painter: _SplashEmblemStoryPainter(
                                    progress: _introCtrl.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: titleAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(titleAnim),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Campus',
                              style: TextStyle(
                                fontFamily: brandFont,
                                fontSize: 33,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Find',
                                style: TextStyle(
                                  fontFamily: brandFont,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    FadeTransition(
                      opacity: titleAnim,
                      child: const Text(
                        'Sistem Barang Hilang & Temuan Kampus',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (!widget.autoRedirect && !widget.loadingSession)
                      FadeTransition(
                        opacity: btnAnim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(btnAnim),
                          child: SizedBox(
                            width: 215,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _starting ? null : _onStartPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isNight
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF0B357A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Mulai',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_rounded, size: 19),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    const Spacer(flex: 1),

                    // Ruang penyangga setinggi area gedung agar konten tepat di tengah langit
                    const SizedBox(height: 185),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnesaRektoratScenePainter extends CustomPainter {
  final double flagProgress;
  final double windPhase;
  final bool isNight;

  _UnesaRektoratScenePainter({
    required this.flagProgress,
    required this.windPhase,
    required this.isNight,
  }) : super(repaint: UnesaLogoCache.notifier);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h - 34;
    final cx = w * 0.5;
    final scale = (w / 430.0).clamp(0.76, 0.95);

    final pathTopW = 22.0 * scale;
    final pathBotW = 40.0 * scale;

    // 1. Bukit Hijau Samping & Halaman Rumput Berlapis
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

    // 2. Jalan Setapak Abu-abu Perspektif di Tengah
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

    // 3. Gedung Rektorat UNESA
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

    // Sayap Kiri & Kanan
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

    // Menara Utama Tengah
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

    // 4. Pohon Organik Alami (2 di kiri, 2 di kanan)
    _drawDetailedTree(canvas, -138, 4, 1.02);
    _drawDetailedTree(canvas, -110, 4, 0.86);
    _drawDetailedTree(canvas, 110, 4, 0.86);
    _drawDetailedTree(canvas, 138, 4, 1.02);

    // 5. Tiang & Bendera Merah Putih di Tengah
    if (flagProgress > 0) {
      const poleTop = -84.0;
      const poleBot = 6.0;

      canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(0, poleBot), width: 22, height: 6),
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

      const flagW = 24.0;
      const flagH = 14.0;
      const flagY = poleTop + 2.5;

      Path flagBand(double y0, double bh) {
        final p = Path()..moveTo(0, y0);
        const steps = 10;
        for (var i = 1; i <= steps; i++) {
          final r = i / steps;
          final x = (flagW * flagProgress) * r;
          final wv = math.sin(windPhase - r * 4.2) * 1.8 * r * flagProgress;
          p.lineTo(x, y0 + wv);
        }
        for (var i = steps; i >= 0; i--) {
          final r = i / steps;
          final x = (flagW * flagProgress) * r;
          final wv = math.sin(windPhase - r * 4.2) * 1.8 * r * flagProgress;
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
    }

    canvas.restore();
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

    // Batang organik dengan pangkal akar & percabangan alami
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

    // Gugusan daun gelap (bayangan rimbun bawah & sela-sela cabang)
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

    // Gugusan daun tengah (hijau daun alami)
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

    // Gugusan daun puncak terkena sinar matahari (hijau muda cerah)
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

    // Goresan detail tulang daun & bayangan ranting di dalam rimbunan
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
  bool shouldRepaint(covariant _UnesaRektoratScenePainter old) =>
      old.flagProgress != flagProgress ||
          old.windPhase != windPhase ||
          old.isNight != isNight;
}

class _FullScreenFirefliesPainter extends CustomPainter {
  final double time;
  const _FullScreenFirefliesPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fireflies = <({
    double fx,
    double fy,
    double ampX,
    double ampY,
    double speed,
    double phase,
    double radius,
    })>[
      (fx: 0.12, fy: 0.14, ampX: 14, ampY: 10, speed: 1.1, phase: 0.3, radius: 2.0),
      (fx: 0.28, fy: 0.21, ampX: 16, ampY: 12, speed: 1.4, phase: 1.7, radius: 1.8),
      (fx: 0.74, fy: 0.16, ampX: 15, ampY: 11, speed: 1.2, phase: 2.9, radius: 2.1),
      (fx: 0.88, fy: 0.24, ampX: 12, ampY: 9, speed: 1.5, phase: 4.1, radius: 1.9),
      (fx: 0.10, fy: 0.38, ampX: 18, ampY: 14, speed: 1.3, phase: 0.8, radius: 2.2),
      (fx: 0.22, fy: 0.52, ampX: 15, ampY: 11, speed: 1.6, phase: 2.2, radius: 1.8),
      (fx: 0.80, fy: 0.40, ampX: 17, ampY: 13, speed: 1.2, phase: 3.5, radius: 2.1),
      (fx: 0.90, fy: 0.56, ampX: 14, ampY: 12, speed: 1.5, phase: 4.9, radius: 1.9),
      (fx: 0.16, fy: 0.68, ampX: 16, ampY: 10, speed: 1.4, phase: 1.1, radius: 2.0),
      (fx: 0.36, fy: 0.73, ampX: 14, ampY: 9, speed: 1.1, phase: 2.7, radius: 1.7),
      (fx: 0.65, fy: 0.71, ampX: 15, ampY: 10, speed: 1.3, phase: 4.0, radius: 1.8),
      (fx: 0.84, fy: 0.67, ampX: 16, ampY: 11, speed: 1.6, phase: 5.3, radius: 2.1),
      (fx: 0.08, fy: 0.85, ampX: 12, ampY: 7, speed: 1.5, phase: 0.5, radius: 2.0),
      (fx: 0.21, fy: 0.92, ampX: 14, ampY: 6, speed: 1.7, phase: 1.9, radius: 1.9),
      (fx: 0.68, fy: 0.89, ampX: 12, ampY: 7, speed: 1.4, phase: 4.4, radius: 1.8),
      (fx: 0.81, fy: 0.93, ampX: 14, ampY: 6, speed: 1.6, phase: 5.6, radius: 2.0),
      (fx: 0.92, fy: 0.84, ampX: 11, ampY: 8, speed: 1.2, phase: 2.4, radius: 2.1),
    ];

    for (final f in fireflies) {
      final t = time * f.speed + f.phase;
      final pos = Offset(
        w * f.fx + math.sin(t) * f.ampX,
        h * f.fy + math.cos(t * 0.85) * f.ampY,
      );
      final pulse = (0.55 + 0.45 * math.sin(t * 2.3)).clamp(0.2, 1.0);

      canvas.drawCircle(
        pos,
        f.radius * 3.2,
        Paint()
          ..color = const Color(0xFFFEF08A).withValues(alpha: 0.28 * pulse),
      );
      canvas.drawCircle(
        pos,
        f.radius,
        Paint()
          ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.95 * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullScreenFirefliesPainter old) =>
      old.time != time;
}

class _NightStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stars = <(double x, double y, double r, double a)>[
      (0.08, 0.10, 1.2, 0.55),
      (0.18, 0.24, 1.5, 0.75),
      (0.27, 0.14, 1.0, 0.45),
      (0.36, 0.31, 1.3, 0.60),
      (0.64, 0.12, 1.4, 0.70),
      (0.73, 0.26, 1.1, 0.50),
      (0.84, 0.16, 1.6, 0.80),
      (0.91, 0.34, 1.2, 0.55),
    ];

    for (final s in stars) {
      canvas.drawCircle(
        Offset(w * s.$1, h * s.$2),
        s.$3,
        Paint()..color = Colors.white.withValues(alpha: s.$4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SkyBody extends StatelessWidget {
  final _DayPhase phase;
  const _SkyBody({required this.phase});

  @override
  Widget build(BuildContext context) {
    if (phase == _DayPhase.night) {
      return SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF152A4A),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFEF08A),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFACC15),
      ),
    );
  }
}

class _SolidCloud extends StatelessWidget {
  final double scale;
  final _DayPhase phase;

  const _SolidCloud({required this.scale, required this.phase});

  @override
  Widget build(BuildContext context) {
    final color = phase == _DayPhase.night
        ? const Color(0xFF1E3A5F)
        : const Color(0xFFE0F2FE);

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 110,
        height: 36,
        child: CustomPaint(
          painter: _SolidCloudPainter(color: color),
        ),
      ),
    );
  }
}

class _SolidCloudPainter extends CustomPainter {
  final Color color;
  _SolidCloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 14, 96, 20),
        const Radius.circular(14),
      ),
      p,
    );
    canvas.drawCircle(const Offset(34, 16), 15, p);
    canvas.drawCircle(const Offset(60, 13), 18, p);
    canvas.drawCircle(const Offset(82, 18), 12, p);
  }

  @override
  bool shouldRepaint(covariant _SolidCloudPainter old) => old.color != color;
}

class _SplashEmblemStoryPainter extends CustomPainter {
  final double progress;
  _SplashEmblemStoryPainter({required this.progress})
      : super(repaint: UnesaLogoCache.notifier);

  double _interval(double start, double end) {
    if (progress <= start) return 0.0;
    if (progress >= end) return 1.0;
    final raw = (progress - start) / (end - start);
    return Curves.easeOutCubic.transform(raw).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    canvas.save();
    canvas.scale(s, s);

    canvas.drawCircle(
        const Offset(60, 60), 60, Paint()..color = const Color(0xFF093275));

    final cyanArc = Paint()
      ..color = const Color(0xFF67E8F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(60, 60), radius: 36),
        -1.97,
        0.80,
        false,
        cyanArc);
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(60, 60), radius: 36),
        2.74,
        0.80,
        false,
        cyanArc);
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(60, 60), radius: 36),
        -0.40,
        0.80,
        false,
        cyanArc);

    canvas.drawArc(
      Rect.fromCircle(center: const Offset(60, 60), radius: 38),
      0.95,
      1.24,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    final t1 = _interval(0.05, 0.22);
    final t2 = _interval(0.12, 0.29);
    final t3 = _interval(0.19, 0.36);
    final t4 = _interval(0.26, 0.43);

    _drawBadgeItem(canvas, 33, 29, t1, () {
      canvas.drawCircle(Offset.zero, 13, Paint()..color = Colors.white);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-7, -3, 14, 10), const Radius.circular(2.5)),
          Paint()..color = const Color(0xFF1D4ED8));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(2, 0, 6, 4), const Radius.circular(1.5)),
          Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(
          const Offset(4.5, 2), 1.0, Paint()..color = Colors.white);
    });

    _drawBadgeItem(canvas, 87, 29, t2, () {
      canvas.drawCircle(Offset.zero, 13, Paint()..color = Colors.white);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-3.5, -10, 7, 20), const Radius.circular(1.5)),
          Paint()..color = const Color(0xFF1D4ED8));
      canvas.drawCircle(
          Offset.zero, 6.8, Paint()..color = const Color(0xFFFBBF24));
      canvas.drawCircle(
          Offset.zero, 4.8, Paint()..color = const Color(0xFF0B357A));
    });

    _drawBadgeItem(canvas, 23, 66, t3, () {
      canvas.drawCircle(Offset.zero, 12.5, Paint()..color = Colors.white);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-4.5, -6, 9, 14), const Radius.circular(2.5)),
          Paint()..color = const Color(0xFF1D4ED8));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-3.5, -8.5, 7, 2.8), const Radius.circular(1)),
          Paint()..color = const Color(0xFF0B357A));
    });

    _drawBadgeItem(canvas, 95, 68, t4, () {
      canvas.drawCircle(Offset.zero, 12.5, Paint()..color = Colors.white);
      canvas.drawCircle(
          const Offset(-3.5, -2.5),
          3.5,
          Paint()
            ..color = const Color(0xFF94A3B8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2);
      canvas.drawLine(
          const Offset(-1.5, 0),
          const Offset(3.5, 5),
          Paint()
            ..color = const Color(0xFF94A3B8)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round);
    });

    final magT = _interval(0.38, 0.60);
    final bldT = _interval(0.55, 0.78);

    if (magT > 0) {
      canvas.save();
      final offsetMag = (1.0 - magT) * 28.0;
      canvas.translate(offsetMag, offsetMag);

      canvas.drawLine(
          const Offset(78, 78),
          const Offset(93, 93),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(
          const Offset(80, 80),
          const Offset(92, 92),
          Paint()
            ..color = const Color(0xFF1D4ED8)
            ..strokeWidth = 5.5
            ..strokeCap = StrokeCap.round);

      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCircle(center: const Offset(60, 60), radius: 24.5)));
      canvas.drawRect(
        const Rect.fromLTWH(34, 34, 52, 52),
        Paint()..color = const Color(0xFF38BDF8),
      );

      if (bldT > 0) {
        canvas.translate(0, (1.0 - bldT) * 18.0);
        canvas.drawRect(const Rect.fromLTWH(34, 75, 52, 12),
            Paint()..color = const Color(0xFF15803D));
        canvas.drawCircle(
            const Offset(38, 70), 7.5, Paint()..color = const Color(0xFF16A34A));
        canvas.drawCircle(
            const Offset(82, 70), 7.5, Paint()..color = const Color(0xFF16A34A));

        canvas.drawPath(
            Path()
              ..moveTo(48, 47)
              ..lineTo(60, 39)
              ..lineTo(72, 47)
              ..close(),
            Paint()..color = const Color(0xFF5C4033));
        canvas.drawRect(
            const Rect.fromLTWH(49, 47, 22, 28), Paint()..color = Colors.white);
        canvas.drawRect(const Rect.fromLTWH(52, 49, 6, 21),
            Paint()..color = const Color(0xFF0284C7));
        canvas.drawRect(const Rect.fromLTWH(62, 49, 6, 21),
            Paint()..color = const Color(0xFF0369A1));
        canvas.drawRect(const Rect.fromLTWH(58.5, 48, 3, 22),
            Paint()..color = const Color(0xFFF8FAFC));
        drawUnesaBadge(canvas, const Offset(60, 57), 7.8);
      }
      canvas.restore();

      canvas.drawCircle(
          const Offset(60, 60),
          25.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawBadgeItem(
      Canvas canvas, double x, double y, double t, VoidCallback drawFn) {
    if (t <= 0) return;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(t, t);
    drawFn();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashEmblemStoryPainter old) =>
      old.progress != progress;
}