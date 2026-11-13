import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampusSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const CampusSplashScreen({super.key, required this.nextScreen});

  @override
  State<CampusSplashScreen> createState() => _CampusSplashScreenState();
}

class _CampusSplashScreenState extends State<CampusSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _gateCtrl;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _gateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _floatCtrl.dispose();
    _gateCtrl.dispose();
    super.dispose();
  }

  void _replayIntro() {
    if (_starting) return;
    _introCtrl.reset();
    _introCtrl.forward();
  }

  Future<void> _onStartPressed() async {
    if (_starting) return;
    setState(() => _starting = true);

    await _gateCtrl.animateTo(0.45, curve: Curves.easeInOutCubic);
    await Future.delayed(const Duration(milliseconds: 260));

    if (!mounted) return;
    final openFuture = _gateCtrl.animateTo(1.0, curve: Curves.easeOutCubic);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    await openFuture;
  }

  @override
  Widget build(BuildContext context) {
    String? brandFont;
    try {
      brandFont = GoogleFonts.syne().fontFamily;
    } catch (_) {}

    final titleAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.68, 0.88, curve: Curves.easeOutCubic),
    );
    final btnAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.80, 1.0, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.48, 0.78, 1.0],
                colors: [
                  Color(0xFF0E74D6),
                  Color(0xFF60B5F7),
                  Color(0xFFDCEFFE),
                  Color(0xFF589F52),
                ],
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: 16,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85)),
                        boxShadow: [
                          BoxShadow(
                            color:
                            const Color(0xFF0B357A).withValues(alpha: 0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'UNIVERSITAS NEGERI SURABAYA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF0B357A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _replayIntro,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_introCtrl, _floatCtrl]),
                    builder: (context, _) {
                      final floatY = (_floatCtrl.value - 0.5) * 10.0;
                      return Transform.translate(
                        offset: Offset(0, floatY),
                        child: Container(
                          width: 152,
                          height: 152,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.74),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B357A)
                                    .withValues(alpha: 0.24),
                                blurRadius: 34,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CustomPaint(
                              painter: _SplashEmblemStoryPainter(
                                  progress: _introCtrl.value),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
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
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF0B357A),
                              Color(0xFF1D4ED8),
                              Color(0xFF0284C7),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Campus',
                            style: TextStyle(
                              fontFamily: brandFont,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Find',
                            style: TextStyle(
                              fontFamily: brandFont,
                              fontSize: 24,
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
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: btnAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(btnAnim),
                    child: SizedBox(
                      width: 220,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _starting ? null : _onStartPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B357A),
                          foregroundColor: Colors.white,
                          elevation: 10,
                          shadowColor:
                          const Color(0xFF0B357A).withValues(alpha: 0.45),
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
                const Spacer(),
                SizedBox(
                  height: 145,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SplashBottomRectoratePainter(),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _gateCtrl,
            builder: (context, _) {
              final v = _gateCtrl.value;
              if (v <= 0.001) return const SizedBox.shrink();

              final double slideT;
              if (v <= 0.45) {
                slideT = -1.0 + (v / 0.45);
              } else {
                slideT = -((v - 0.45) / 0.55) * 1.05;
              }

              return IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final halfW = constraints.maxWidth / 2;
                    return Stack(
                      children: [
                        Positioned(
                          left: slideT * halfW,
                          top: 0,
                          bottom: 0,
                          width: halfW,
                          child: CustomPaint(
                            painter: _UnesaGateHalfPainter(isLeft: true),
                          ),
                        ),
                        Positioned(
                          right: slideT * halfW,
                          top: 0,
                          bottom: 0,
                          width: halfW,
                          child: CustomPaint(
                            painter: _UnesaGateHalfPainter(isLeft: false),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SplashEmblemStoryPainter extends CustomPainter {
  final double progress;
  _SplashEmblemStoryPainter({required this.progress});

  double _interval(double start, double end) {
    if (progress <= start) return 0.0;
    if (progress >= end) return 1.0;
    return Curves.easeOutBack.transform((progress - start) / (end - start));
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
      final offsetMag = (1.0 - magT.clamp(0.0, 1.0)) * 28.0;
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
      canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: const Offset(60, 60), radius: 24.5)));
      canvas.drawRect(
        const Rect.fromLTWH(34, 34, 52, 52),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF38BDF8), Color(0xFFBAE6FD)],
          ).createShader(const Rect.fromLTWH(34, 34, 52, 52)),
      );

      if (bldT > 0) {
        canvas.translate(0, (1.0 - bldT.clamp(0.0, 1.0)) * 18.0);
        canvas.drawRect(const Rect.fromLTWH(34, 75, 52, 12),
            Paint()..color = const Color(0xFF4C964E));
        canvas.drawCircle(
            const Offset(38, 70), 7.5, Paint()..color = const Color(0xFF16A34A));
        canvas.drawCircle(
            const Offset(82, 70), 7.5, Paint()..color = const Color(0xFF16A34A));

        canvas.drawPath(
            Path()
              ..moveTo(36, 64)
              ..lineTo(43, 60)
              ..lineTo(49, 64)
              ..close(),
            Paint()..color = const Color(0xFF4B3B36));
        canvas.drawRect(const Rect.fromLTWH(37, 64, 12, 11),
            Paint()..color = const Color(0xFFF8FAFC));
        canvas.drawRect(const Rect.fromLTWH(37, 64, 12, 2.8),
            Paint()..color = const Color(0xFF1D63B8));

        canvas.drawPath(
            Path()
              ..moveTo(71, 64)
              ..lineTo(77, 60)
              ..lineTo(84, 64)
              ..close(),
            Paint()..color = const Color(0xFF4B3B36));
        canvas.drawRect(const Rect.fromLTWH(71, 64, 12, 11),
            Paint()..color = const Color(0xFFE2E8F0));
        canvas.drawRect(const Rect.fromLTWH(71, 64, 12, 2.8),
            Paint()..color = const Color(0xFF1D63B8));

        canvas.drawPath(
            Path()
              ..moveTo(48, 47)
              ..lineTo(60, 39)
              ..lineTo(72, 47)
              ..close(),
            Paint()..color = const Color(0xFF4B3B36));
        canvas.drawRect(
            const Rect.fromLTWH(49, 47, 22, 28), Paint()..color = Colors.white);
        canvas.drawRect(const Rect.fromLTWH(52, 49, 6, 21),
            Paint()..color = const Color(0xFF0B5ED7));
        canvas.drawRect(const Rect.fromLTWH(62, 49, 6, 21),
            Paint()..color = const Color(0xFF1D74E8));
        canvas.drawRect(const Rect.fromLTWH(58.5, 48, 3, 22),
            Paint()..color = const Color(0xFFF8FAFC));
        canvas.drawRect(const Rect.fromLTWH(57, 48.5, 6, 6.8),
            Paint()..color = const Color(0xFF0B357A));
        canvas.drawRect(const Rect.fromLTWH(52, 70, 2.4, 5),
            Paint()..color = const Color(0xFFC2410C));
        canvas.drawRect(const Rect.fromLTWH(65.6, 70, 2.4, 5),
            Paint()..color = const Color(0xFFC2410C));
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
    canvas.scale(t.clamp(0.0, 1.15), t.clamp(0.0, 1.15));
    drawFn();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashEmblemStoryPainter old) =>
      old.progress != progress;
}

class _SplashBottomRectoratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 440.0;
    final sy = size.height / 135.0;
    canvas.save();
    canvas.scale(sx, sy);

    final bush = Path()
      ..moveTo(0, 104)
      ..quadraticBezierTo(55, 94, 110, 103)
      ..quadraticBezierTo(165, 110, 220, 102)
      ..quadraticBezierTo(275, 94, 330, 103)
      ..quadraticBezierTo(385, 110, 440, 100)
      ..lineTo(440, 115)
      ..lineTo(0, 115)
      ..close();
    canvas.drawPath(bush, Paint()..color = const Color(0xFF86BC94));

    canvas.drawPath(
        Path()
          ..moveTo(56, 66)
          ..lineTo(112, 53)
          ..lineTo(168, 66)
          ..close(),
        Paint()..color = const Color(0xFF4B3B36));
    canvas.drawPath(
        Path()
          ..moveTo(272, 66)
          ..lineTo(328, 53)
          ..lineTo(384, 66)
          ..close(),
        Paint()..color = const Color(0xFF4B3B36));

    canvas.drawRect(const Rect.fromLTWH(60, 66, 104, 44),
        Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRect(const Rect.fromLTWH(60, 66, 104, 10),
        Paint()..color = const Color(0xFF1D63B8));
    canvas.drawRect(const Rect.fromLTWH(276, 66, 104, 44),
        Paint()..color = const Color(0xFFEFF6FF));
    canvas.drawRect(const Rect.fromLTWH(276, 66, 104, 10),
        Paint()..color = const Color(0xFF1D63B8));

    canvas.drawPath(
        Path()
          ..moveTo(164, 28)
          ..lineTo(220, 10)
          ..lineTo(276, 28)
          ..close(),
        Paint()..color = const Color(0xFF4B3B36));
    canvas.drawPath(
        Path()
          ..moveTo(220, 10)
          ..lineTo(276, 28)
          ..lineTo(220, 28)
          ..close(),
        Paint()..color = const Color(0xFF634F48));

    canvas.drawLine(
        const Offset(220, 5),
        const Offset(220, 10),
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 1.2);
    canvas.drawCircle(
        const Offset(220, 4.5), 1.4, Paint()..color = const Color(0xFFF59E0B));

    canvas.drawRect(
        const Rect.fromLTWH(168, 28, 104, 82), Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(183, 33, 28, 62),
        Paint()..color = const Color(0xFF0B5ED7));
    canvas.drawRect(const Rect.fromLTWH(229, 33, 28, 62),
        Paint()..color = const Color(0xFF1D74E8));
    canvas.drawRect(const Rect.fromLTWH(213, 31, 14, 64),
        Paint()..color = const Color(0xFFF8FAFC));

    canvas.drawRect(const Rect.fromLTWH(208, 33, 24, 26),
        Paint()..color = const Color(0xFF0B357A));
    canvas.drawRect(
        const Rect.fromLTWH(208, 33, 24, 26),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    canvas.drawPath(
        Path()
          ..moveTo(220, 36.5)
          ..lineTo(221.6, 47.5)
          ..lineTo(218.4, 47.5)
          ..close(),
        Paint()..color = const Color(0xFFEAB308));
    final wingP = Paint()
      ..color = const Color(0xFFEAB308)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(216.5, 43.5 - i * 0.5),
              width: 7.5 - i * 0.6,
              height: 9.0 - i * 0.8),
          1.4,
          2.2,
          false,
          wingP);
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(223.5, 43.5 - i * 0.5),
              width: 7.5 - i * 0.6,
              height: 9.0 - i * 0.8),
          -0.45,
          2.2,
          false,
          wingP);
    }
    final tp = TextPainter(
      text: const TextSpan(
        text: 'UNESA',
        style: TextStyle(
            color: Color(0xFFFACC15),
            fontSize: 4.2,
            fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(220 - tp.width / 2, 51.5));

    canvas.drawRect(const Rect.fromLTWH(183, 95, 10, 15),
        Paint()..color = const Color(0xFFC2410C));
    canvas.drawRect(const Rect.fromLTWH(247, 95, 10, 15),
        Paint()..color = const Color(0xFFC2410C));

    canvas.drawRect(const Rect.fromLTWH(0, 109, 440, 26),
        Paint()..color = const Color(0xFF4C964E));
    canvas.drawPath(
        Path()
          ..moveTo(208, 109)
          ..lineTo(232, 109)
          ..lineTo(246, 135)
          ..lineTo(194, 135)
          ..close(),
        Paint()..color = const Color(0xFFE2E8F0));

    canvas.drawLine(
        const Offset(220, 62),
        const Offset(220, 112),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.6);
    canvas.drawCircle(
        const Offset(220, 61), 1.8, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawRect(const Rect.fromLTWH(221, 63, 15, 4.5),
        Paint()..color = const Color(0xFFDC2626));
    canvas.drawRect(
        const Rect.fromLTWH(221, 67.5, 15, 4.5), Paint()..color = Colors.white);

    canvas.drawRect(const Rect.fromLTWH(24, 88, 4, 24),
        Paint()..color = const Color(0xFF5C4033));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(26, 78), width: 44, height: 30),
        Paint()..color = const Color(0xFF2E7D32));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(29, 74), width: 32, height: 22),
        Paint()..color = const Color(0xFF43A047));

    canvas.drawRect(const Rect.fromLTWH(412, 88, 4, 24),
        Paint()..color = const Color(0xFF5C4033));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(414, 78), width: 44, height: 30),
        Paint()..color = const Color(0xFF2E7D32));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(411, 74), width: 32, height: 22),
        Paint()..color = const Color(0xFF43A047));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UnesaGateHalfPainter extends CustomPainter {
  final bool isLeft;
  _UnesaGateHalfPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 220.0;
    final sy = size.height / 840.0;
    canvas.save();
    canvas.scale(sx, sy);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 220, 712),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E74D6), Color(0xFF60B5F7), Color(0xFFDCEFFE)],
        ).createShader(const Rect.fromLTWH(0, 0, 220, 712)),
    );
    canvas.drawRect(const Rect.fromLTWH(0, 712, 220, 128),
        Paint()..color = const Color(0xFF475569));
    canvas.drawRect(const Rect.fromLTWH(0, 712, 220, 8),
        Paint()..color = const Color(0xFF94A3B8));

    final pedPath = isLeft
        ? (Path()
      ..moveTo(4, 226)
      ..lineTo(112, 188)
      ..lineTo(112, 175)
      ..lineTo(220, 136)
      ..lineTo(220, 236)
      ..lineTo(4, 236)
      ..close())
        : (Path()
      ..moveTo(0, 136)
      ..lineTo(108, 175)
      ..lineTo(108, 188)
      ..lineTo(216, 226)
      ..lineTo(216, 236)
      ..lineTo(0, 236)
      ..close());

    canvas.drawPath(
      pedPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF1ECE0), Color(0xFFFFFDF8), Color(0xFFEAE3D0)],
        ).createShader(const Rect.fromLTWH(0, 136, 220, 100)),
    );
    canvas.drawPath(
      pedPath,
      Paint()
        ..color = const Color(0xFFD6CEB8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    canvas.drawRect(const Rect.fromLTWH(0, 234, 220, 10),
        Paint()..color = const Color(0xFFE7E0CC));
    canvas.drawRect(const Rect.fromLTWH(0, 244, 220, 60),
        Paint()..color = const Color(0xFFFFFDF8));
    canvas.drawRect(const Rect.fromLTWH(0, 304, 220, 5),
        Paint()..color = const Color(0xFFFEF08A));
    canvas.drawRect(const Rect.fromLTWH(0, 309, 220, 12),
        Paint()..color = const Color(0xFFD6CEB8));
    canvas.drawRect(
      const Rect.fromLTWH(0, 321, 220, 95),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFDE047).withValues(alpha: 0.65),
            const Color(0xFFFEF08A).withValues(alpha: 0.0),
          ],
        ).createShader(const Rect.fromLTWH(0, 321, 220, 95)),
    );

    if (isLeft) {
      _drawText(canvas, 'ꦈꦤꦺꦱ', 29, 270, 9.0, const Color(0xFF334155));
      _drawGoldTextRight(canvas, 'UNIVERSITAS NE', 218, 271, 13.0);
    } else {
      _drawGoldTextLeft(canvas, 'GERI SURABAYA', 2, 271, 13.0);
      _drawText(canvas, 'ꦈꦤꦺꦱ', 191, 270, 9.0, const Color(0xFF334155));
    }

    final pillarCols = isLeft ? [8.0, 52.0, 184.0] : [10.0, 144.0, 184.0];
    for (final px in pillarCols) {
      canvas.drawRect(
        Rect.fromLTWH(px, 320, 28, 398),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFDFD7C2), Color(0xFFFFFDF8), Color(0xFFD4CCB4)],
          ).createShader(Rect.fromLTWH(px, 320, 28, 398)),
      );
      canvas.drawRect(Rect.fromLTWH(px - 4, 318, 36, 11),
          Paint()..color = const Color(0xFFFFFDF8));
      canvas.drawRect(Rect.fromLTWH(px - 4, 704, 36, 16),
          Paint()..color = const Color(0xFFE7E0CC));
    }

    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 220, 260));
    canvas.translate(isLeft ? 220.0 : 0.0, 128.0);
    _drawGarudaPancasila3D(canvas);
    canvas.restore();

    canvas.restore();
  }

  void _drawGarudaPancasila3D(Canvas canvas) {
    canvas.drawCircle(
      const Offset(0, -24),
      64,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDE047).withValues(alpha: 0.45),
            const Color(0xFFFDE047).withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: const Offset(0, -24), radius: 64)),
    );

    final gold3D = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF3B0),
          Color(0xFFFACC15),
          Color(0xFFD97706),
          Color(0xFF92400E),
        ],
      ).createShader(const Rect.fromLTWH(-64, -92, 128, 128));

    final bronzeRim = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (final dir in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(dir, 1.0);

      final wingShadow = Path()
        ..moveTo(4, -8)
        ..quadraticBezierTo(36, -6, 62, -68)
        ..quadraticBezierTo(50, -34, 42, -16)
        ..quadraticBezierTo(30, 4, 6, 4)
        ..close();
      canvas.drawPath(
        wingShadow.shift(const Offset(2.2, 3.0)),
        Paint()
          ..color = const Color(0xFF451A03).withValues(alpha: 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      for (int i = 0; i < 17; i++) {
        final t = i / 16.0;
        final baseX = 7.0 + _mathSin(t * 2.4) * 5.0;
        final baseY = -26.0 + t * 26.0;
        final tipX = 59.0 - _mathPow(t, 1.35) * 32.0;
        final tipY = -69.0 + t * 76.0;
        final ctrlX = (baseX + tipX) * 0.56 + 6.0;
        final ctrlY = (baseY + tipY) * 0.52 + 6.0;

        final feather = Path()
          ..moveTo(baseX, baseY - 2.4)
          ..quadraticBezierTo(ctrlX, ctrlY - 2.6, tipX, tipY)
          ..quadraticBezierTo(ctrlX - 1.5, ctrlY + 2.8, baseX, baseY + 2.4)
          ..close();

        canvas.drawPath(feather, gold3D);
        canvas.drawPath(feather, bronzeRim);

        canvas.drawLine(
          Offset(baseX + 2, baseY),
          Offset(tipX - 3, tipY + 0.5),
          Paint()
            ..color = const Color(0xFFFEF9C3).withValues(alpha: 0.72)
            ..strokeWidth = 0.65,
        );
      }

      final shoulder = Path()
        ..moveTo(6, -28)
        ..quadraticBezierTo(24, -30, 32, -14)
        ..quadraticBezierTo(22, -2, 6, -4)
        ..close();
      canvas.drawPath(shoulder, gold3D);
      canvas.drawPath(shoulder, bronzeRim);

      canvas.restore();
    }

    for (int e = -3; e <= 3; e++) {
      final ex = e * 2.8;
      final tailPath = Path()
        ..moveTo(ex - 2.0, 8)
        ..lineTo(ex - 2.8, 29 - e.abs() * 1.1)
        ..lineTo(ex, 32 - e.abs() * 1.1)
        ..lineTo(ex + 2.8, 29 - e.abs() * 1.1)
        ..lineTo(ex + 2.0, 8)
        ..close();
      canvas.drawPath(tailPath, gold3D);
      canvas.drawPath(tailPath, bronzeRim);
    }

    final neckPath = Path()
      ..moveTo(-9, -28)
      ..lineTo(-8, -46)
      ..lineTo(8, -46)
      ..lineTo(9, -28)
      ..close();
    canvas.drawPath(neckPath, gold3D);
    canvas.drawPath(neckPath, bronzeRim);

    for (double ny = -43; ny <= -31; ny += 3.5) {
      for (double nx = -5.5; nx <= 5.5; nx += 3.6) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(nx, ny), width: 3.6, height: 3.2),
          0.1,
          2.9,
          false,
          bronzeRim,
        );
      }
    }

    final headPath = Path()
      ..moveTo(-7, -45)
      ..quadraticBezierTo(-11, -52, -7, -57)
      ..lineTo(-3, -55)
      ..quadraticBezierTo(2, -59, 8, -55)
      ..quadraticBezierTo(15, -54, 17, -49)
      ..quadraticBezierTo(11, -48, 8, -49)
      ..lineTo(14, -46)
      ..quadraticBezierTo(9, -44, 6, -45)
      ..close();
    canvas.drawPath(headPath, gold3D);
    canvas.drawPath(headPath, bronzeRim);
    canvas.drawCircle(
        const Offset(5.5, -52.2), 1.1, Paint()..color = const Color(0xFF451A03));

    for (final dir in [-1.0, 1.0]) {
      final leg = Path()
        ..moveTo(dir * 7, 4)
        ..lineTo(dir * 16, 15)
        ..lineTo(dir * 12, 18)
        ..lineTo(dir * 4, 8)
        ..close();
      canvas.drawPath(leg, gold3D);
      canvas.drawPath(leg, bronzeRim);
    }

    final shieldPath = Path()
      ..moveTo(-17, -31)
      ..lineTo(17, -31)
      ..lineTo(16, -9)
      ..quadraticBezierTo(14, 2, 0, 7)
      ..quadraticBezierTo(-14, 2, -16, -9)
      ..close();

    canvas.drawPath(
      shieldPath.shift(const Offset(1.5, 2.2)),
      Paint()..color = const Color(0xFF451A03).withValues(alpha: 0.45),
    );

    canvas.save();
    canvas.clipPath(shieldPath);

    canvas.drawRect(const Rect.fromLTWH(-18, -32, 18, 17),
        Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(
        const Offset(-9, -22.5), 3.0, Paint()..color = const Color(0xFF1E293B));
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(-9, -25.2), width: 6.5, height: 3.2),
        0.1,
        2.9,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    canvas.drawRect(
        const Rect.fromLTWH(0, -32, 18, 17), Paint()..color = Colors.white);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(9, -24.5), width: 8.5, height: 5.5),
        Paint()..color = const Color(0xFF15803D));
    canvas.drawRect(const Rect.fromLTWH(8.2, -22, 1.6, 4),
        Paint()..color = const Color(0xFF78350F));

    canvas.drawRect(
        const Rect.fromLTWH(-18, -15, 18, 24), Paint()..color = Colors.white);
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(-6, -8), width: 10, height: 12),
        1.5,
        1.7,
        false,
        Paint()
          ..color = const Color(0xFF16A34A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(-8, -7), width: 10, height: 12),
        1.5,
        1.7,
        false,
        Paint()
          ..color = const Color(0xFFEAB308)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);

    canvas.drawRect(const Rect.fromLTWH(0, -15, 18, 24),
        Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(
        const Offset(8.5, -7),
        4.2,
        Paint()
          ..color = const Color(0xFFFDE047)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);

    canvas.drawLine(
        const Offset(-18, -15),
        const Offset(18, -15),
        Paint()
          ..color = const Color(0xFF0F172A)
          ..strokeWidth = 2.0);

    final centerShield = Path()
      ..moveTo(-6.5, -22.5)
      ..lineTo(6.5, -22.5)
      ..lineTo(6.0, -12.5)
      ..quadraticBezierTo(5.0, -7.5, 0, -5.5)
      ..quadraticBezierTo(-5.0, -7.5, -6.0, -12.5)
      ..close();
    canvas.drawPath(centerShield, Paint()..color = const Color(0xFF0F172A));
    canvas.drawPath(
        centerShield,
        Paint()
          ..color = const Color(0xFFFACC15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);
    _drawStar(canvas, 0, -14.2, 4.4, const Color(0xFFFACC15));

    canvas.restore();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = const Color(0xFFFACC15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final ribbon = Path()
      ..moveTo(-34, 9)
      ..quadraticBezierTo(-18, 16, 0, 16)
      ..quadraticBezierTo(18, 16, 34, 9)
      ..lineTo(31, 18)
      ..quadraticBezierTo(16, 24, 0, 24)
      ..quadraticBezierTo(-16, 24, -31, 18)
      ..close();
    canvas.drawPath(ribbon, Paint()..color = const Color(0xFFFFFDF8));
    canvas.drawPath(ribbon, bronzeRim);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'BHINNEKA TUNGGAL IKA',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 4.1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 17.5));
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -1.5708 + i * 0.628318;
      final rad = i.isEven ? r : r * 0.42;
      final x = cx + _mathCos(angle) * rad;
      final y = cy + _mathSin(angle) * rad;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(
      Canvas canvas, String text, double cx, double y, double size, Color c) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: c, fontSize: size, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  void _drawGoldTextRight(
      Canvas canvas, String text, double rx, double y, double size) {
    final shadow = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: const Color(0xFF92400E),
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8)),
      textDirection: TextDirection.ltr,
    )..layout();
    shadow.paint(canvas, Offset(rx - shadow.width + 0.8, y + 0.8));

    final front = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: const Color(0xFFFACC15),
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8)),
      textDirection: TextDirection.ltr,
    )..layout();
    front.paint(canvas, Offset(rx - front.width, y));
  }

  void _drawGoldTextLeft(
      Canvas canvas, String text, double lx, double y, double size) {
    final shadow = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: const Color(0xFF92400E),
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8)),
      textDirection: TextDirection.ltr,
    )..layout();
    shadow.paint(canvas, Offset(lx + 0.8, y + 0.8));

    final front = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: const Color(0xFFFACC15),
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8)),
      textDirection: TextDirection.ltr,
    )..layout();
    front.paint(canvas, Offset(lx, y));
  }

  @override
  bool shouldRepaint(covariant _UnesaGateHalfPainter old) =>
      old.isLeft != isLeft;
}

double _mathSin(double x) {
  x = x % (2 * 3.141592653589793);
  double term = x;
  double sum = x;
  for (int i = 1; i <= 7; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    sum += term;
  }
  return sum;
}

double _mathCos(double x) => _mathSin(x + 1.5707963267948966);

double _mathPow(double base, double exp) {
  if (base <= 0) return 0;
  double ln = 0;
  double y = (base - 1) / (base + 1);
  double y2 = y * y;
  double term = y;
  for (int i = 1; i <= 15; i += 2) {
    ln += term / i;
    term *= y2;
  }
  ln *= 2;
  final z = exp * ln;
  double res = 1.0;
  double t = 1.0;
  for (int i = 1; i <= 15; i++) {
    t *= z / i;
    res += t;
  }
  return res;
}