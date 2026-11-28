import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screens.dart';
import 'cartoon.dart';
import 'unesa_logo.dart';

typedef AuthChoiceScreen = ChooseLoginScreen;

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
      duration: const Duration(seconds: 4),
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
    Future.delayed(const Duration(milliseconds: 2000), () {
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

    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 18;
    final screenH = MediaQuery.of(context).size.height;

    final logoAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
    );
    final titleAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOutCubic),
    );
    final btnAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF08102A) : const Color(0xFF0E74D6),
      body: CartoonHeader(
        height: screenH,
        bottomRadius: 0,
        showBuilding: true,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Lencana Universitas Negeri Surabaya
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isNight
                      ? const Color(0xFF132A4A).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isNight
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
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
                        color: isNight ? Colors.white : const Color(0xFF0B357A),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Emblem Logo CampusFind
              GestureDetector(
                onTap: _replayIntro,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_introCtrl, _floatCtrl]),
                  builder: (context, _) {
                    final floatY = math.sin(_floatCtrl.value * math.pi) * 4.0;
                    return Opacity(
                      opacity: logoAnim.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.72 + (logoAnim.value * 0.28),
                        child: Transform.translate(
                          offset: Offset(0, floatY),
                          child: Container(
                            width: 136,
                            height: 136,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFBAE6FD),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
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
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Judul CampusFind
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
                          shadows: const [
                            Shadow(
                              color: Color(0x55000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1080A6),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
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
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Tombol Mulai
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
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.3,
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

              const Spacer(flex: 2),

              // Ruang penyangga di bawah agar area Gedung Rektorat UNESA & Bendera terlihat utuh
              SizedBox(height: screenH * 0.28),
            ],
          ),
        ),
      ),
    );
  }
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