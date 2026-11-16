import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampusSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final bool autoRedirect;
  const CampusSplashScreen({
    super.key,
    required this.nextScreen,
    this.autoRedirect = false,
  });

  @override
  State<CampusSplashScreen> createState() => _CampusSplashScreenState();
}

class _CampusSplashScreenState extends State<CampusSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _floatCtrl;
  bool _starting = false;
  bool _autoScheduled = false;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

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
    Future.delayed(const Duration(milliseconds: 1650), () {
      if (mounted) _onStartPressed();
    });
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _floatCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    String? brandFont;
    try {
      brandFont = GoogleFonts.syne().fontFamily;
    } catch (_) {}

    final titleAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    );
    final btnAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOutCubic),
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
                stops: [0.0, 0.48, 0.80, 1.0],
                colors: [
                  Color(0xFF0E74D6),
                  Color(0xFF60B5F7),
                  Color(0xFFDCEFFE),
                  Color(0xFFE8F5E9),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SplashBottomHillsPainter(),
              ),
            ),
          ),
          SafeArea(
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
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: titleAnim,
                  child: const Text(
                    'Sistem Barang Hilang & Temuan Kampus',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.autoRedirect)
                  FadeTransition(
                    opacity: titleAnim,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF0B357A),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Memuat sesi akun...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B357A),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                const Spacer(flex: 2),
              ],
            ),
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

class _SplashBottomHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final backHill = Path()
      ..moveTo(0, h * 0.42)
      ..quadraticBezierTo(w * 0.28, h * 0.14, w * 0.62, h * 0.36)
      ..quadraticBezierTo(w * 0.84, h * 0.50, w, h * 0.28)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backHill, Paint()..color = const Color(0xFF81C784));

    final frontHill = Path()
      ..moveTo(0, h * 0.56)
      ..quadraticBezierTo(w * 0.35, h * 0.72, w * 0.68, h * 0.48)
      ..quadraticBezierTo(w * 0.88, h * 0.36, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontHill, Paint()..color = const Color(0xFF1FA35C));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}