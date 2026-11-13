import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'core.dart';
import 'widgets.dart';

// ------------------------------------------------------------------ painter statis (dipakai SplashScreen)
class CampusPainter extends CustomPainter {
  final bool night;
  final double bx, bs, sunX, groundY;
  final double time;

  CampusPainter({
    this.night = false,
    this.bx = .5,
    this.bs = .6,
    this.sunX = .82,
    this.groundY = .80,
    this.time = 1.2,
  });

  static final List<List<_LeafSpray>> _defaultCrowns = [
    _CartoonHeaderState._generateOrganicCanopy(1.14, 101),
    _CartoonHeaderState._generateOrganicCanopy(0.88, 202),
    _CartoonHeaderState._generateOrganicCanopy(0.90, 303),
    _CartoonHeaderState._generateOrganicCanopy(1.14, 404),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _CampusAtmospherePainter(
      time: time,
      night: night ? 1.0 : 0.0,
      sunXRatio: sunX,
      treeCrowns: _defaultCrowns,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CampusPainter old) =>
      old.night != night || old.time != time || old.sunX != sunX;
}

// ------------------------------------------------------------------ header bangunan kartun 3D UNESA
class CartoonHeader extends StatefulWidget {
  final double height, bx, bs, groundY, sunX;
  final Widget? child;

  const CartoonHeader({
    super.key,
    this.height = 320,
    this.bx = .5,
    this.bs = .52,
    this.groundY = .80,
    this.sunX = .82,
    this.child,
  });

  @override
  State<CartoonHeader> createState() => _CartoonHeaderState();
}

class _CartoonHeaderState extends State<CartoonHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<List<_LeafSpray>> _treeCrowns;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _treeCrowns = [
      _generateOrganicCanopy(1.14, 101),
      _generateOrganicCanopy(0.88, 202),
      _generateOrganicCanopy(0.90, 303),
      _generateOrganicCanopy(1.14, 404),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static List<_LeafSpray> _generateOrganicCanopy(double s, int seed) {
    int val = seed;
    double rand() {
      val = (val * 16807) % 2147483647;
      return (val - 1) / 2147483646;
    }

    final boughs = [
      (bx: -21 * s, by: -12 * s, rx: 14 * s, ry: 7.5 * s, layer: 0),
      (bx: 20 * s, by: -11 * s, rx: 14 * s, ry: 7.5 * s, layer: 0),
      (bx: -4 * s, by: -14 * s, rx: 12 * s, ry: 7.0 * s, layer: 0),
      (bx: -17 * s, by: -22 * s, rx: 15 * s, ry: 8.5 * s, layer: 1),
      (bx: 16 * s, by: -21 * s, rx: 15 * s, ry: 8.5 * s, layer: 1),
      (bx: 1 * s, by: -24 * s, rx: 14 * s, ry: 8.0 * s, layer: 1),
      (bx: -9 * s, by: -32 * s, rx: 13 * s, ry: 7.5 * s, layer: 2),
      (bx: 9 * s, by: -31 * s, rx: 13 * s, ry: 7.5 * s, layer: 2),
      (bx: 0.0, by: -38 * s, rx: 14 * s, ry: 7.5 * s, layer: 3),
    ];

    final sprays = <_LeafSpray>[];
    for (final b in boughs) {
      const count = 22;
      for (int i = 0; i < count; i++) {
        final angle = (i / count) * pi * 2 + rand() * 0.65;
        final dist = 0.18 + rand() * 0.85;
        final px = b.bx + cos(angle) * b.rx * dist;
        final py = b.by + sin(angle) * b.ry * dist;
        final sunExposure = (px * 0.65 - py * 0.85) / (25 * s);
        sprays.add(_LeafSpray(
          x: px,
          y: py,
          len: (3.2 + rand() * 2.8) * s,
          wid: (1.5 + rand() * 1.3) * s,
          rot: (rand() - 0.5) * 1.4,
          layer: b.layer,
          sunExposure: sunExposure,
        ));
      }
    }
    return sprays;
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _CampusAtmospherePainter(
                  time: _ctrl.value * 60.0,
                  night: dark ? 1.0 : 0.0,
                  sunXRatio: widget.sunX,
                  treeCrowns: _treeCrowns,
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class _LeafSpray {
  final double x, y, len, wid, rot, sunExposure;
  final int layer;

  const _LeafSpray({
    required this.x,
    required this.y,
    required this.len,
    required this.wid,
    required this.rot,
    required this.layer,
    required this.sunExposure,
  });
}

class _CampusAtmospherePainter extends CustomPainter {
  final double time;
  final double night;
  final double sunXRatio;
  final List<List<_LeafSpray>> treeCrowns;

  _CampusAtmospherePainter({
    required this.time,
    required this.night,
    required this.sunXRatio,
    required this.treeCrowns,
  });

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Color _lerpRGB(List<int> c1, List<int> c2, double t) => Color.fromARGB(
    255,
    _lerp(c1[0].toDouble(), c2[0].toDouble(), t).round(),
    _lerp(c1[1].toDouble(), c2[1].toDouble(), t).round(),
    _lerp(c1[2].toDouble(), c2[2].toDouble(), t).round(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = night;

    // Penyesuaian skala vertikal agar atap dan penangkal petir gedung utuh tidak terpotong
    final scaleH = h / 352.0;
    final baseY = 298.0 * scaleH;

    // 1. LANGIT GRADASI SIANG / MALAM
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.58, 1.0],
        colors: [
          _lerpRGB([14, 116, 214], [8, 16, 42], n),
          _lerpRGB([112, 194, 252], [17, 34, 74], n),
          _lerpRGB([224, 242, 254], [28, 52, 98], n),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. BINTANG MALAM
    if (n > 0.25) {
      for (int i = 0; i < 34; i++) {
        final sx = (((i * 73) % 100) / 100.0) * w;
        final sy = (((i * 41) % 52) / 100.0) * h;
        final r = (i % 3 == 0) ? 1.5 : 1.0;
        final twinkle = 0.45 + 0.55 * sin(time * 2.4 + i * 0.7);
        canvas.drawCircle(
          Offset(sx, sy),
          r,
          Paint()..color = Colors.white.withValues(alpha: n * twinkle * 0.85),
        );
      }
    }

    // 3. MATAHARI (SIANG) & BULAN PURNAMA (MALAM)
    final sunX = w * sunXRatio;
    final sunY = 76.0 * scaleH + n * 165.0;

    if (n < 0.85) {
      final sunAlpha = (1.0 - n * 1.25).clamp(0.0, 1.0);
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFBEB).withValues(alpha: 0.85 * sunAlpha),
            const Color(0xFFFDE047).withValues(alpha: 0.32 * sunAlpha),
            const Color(0xFFFDE047).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 68));
      canvas.drawCircle(Offset(sunX, sunY), 68, haloPaint);
      canvas.drawCircle(
        Offset(sunX, sunY),
        15,
        Paint()..color = const Color(0xFFFFFDF2).withValues(alpha: sunAlpha),
      );
    }

    if (n > 0.15) {
      final moonX = w * 0.80;
      final moonY = 74.0 * scaleH + (1.0 - n) * 140.0;
      final moonHalo = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFEF9C3).withValues(alpha: 0.42 * n),
            const Color(0xFFE0F2FE).withValues(alpha: 0.18 * n),
            const Color(0xFFE0F2FE).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(moonX, moonY), radius: 56));
      canvas.drawCircle(Offset(moonX, moonY), 56, moonHalo);

      canvas.save();
      canvas.translate(moonX, moonY);
      canvas.drawCircle(
        Offset.zero,
        16,
        Paint()
          ..color = const Color(0xFFFEF08A).withValues(alpha: 0.35 * n)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset.zero,
        14,
        Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: n),
      );
      final mariaPaint = Paint()
        ..color = const Color(0xFFE2DAAC).withValues(alpha: 0.38 * n);
      canvas.drawCircle(const Offset(-4.2, -3.2), 3.2, mariaPaint);
      canvas.drawCircle(const Offset(4.8, 2.6), 2.4, mariaPaint);
      canvas.drawCircle(const Offset(-2.0, 5.2), 1.8, mariaPaint);
      canvas.restore();
    }

    // 4. AWAN VOLUMETRIK BERGERAK & BURUNG TERBANG
    final clouds = [
      (x: 35.0, y: 74.0 * scaleH, scale: 0.96, speed: 6.5, alpha: 0.90),
      (x: 245.0, y: 62.0 * scaleH, scale: 0.82, speed: 4.5, alpha: 0.80),
      (x: 155.0, y: 98.0 * scaleH, scale: 0.72, speed: 8.0, alpha: 0.74),
      (x: 350.0, y: 88.0 * scaleH, scale: 0.88, speed: 5.5, alpha: 0.84),
    ];
    for (final c in clouds) {
      final span = w + 150.0;
      final cx = ((c.x + time * c.speed + 75.0) % span) - 75.0;
      _drawSoftCloud(canvas, cx, c.y, c.scale, c.alpha * (1.0 - n * 0.62), n);
    }

    if (n < 0.55) {
      final birdPaint = Paint()
        ..color = const Color(0xFF1E3A5F).withValues(alpha: (1.0 - n * 1.6) * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      final birds = [
        (x: 95.0, y: 84.0 * scaleH, speed: 18.0, off: 0.2, s: 0.78),
        (x: 112.0, y: 78.0 * scaleH, speed: 18.0, off: 1.4, s: 0.65),
        (x: 295.0, y: 96.0 * scaleH, speed: 14.0, off: 2.3, s: 0.72),
      ];
      for (final b in birds) {
        final bx = ((b.x + time * b.speed + 30.0) % (w + 60.0)) - 30.0;
        final flap = sin(time * 5.2 + b.off) * 3.2 * b.s;
        final path = Path()
          ..moveTo(bx - 5 * b.s, b.y + flap)
          ..quadraticBezierTo(bx - 2.2 * b.s, b.y - 2.5 * b.s, bx, b.y)
          ..quadraticBezierTo(bx + 2.2 * b.s, b.y - 2.5 * b.s, bx + 5 * b.s, b.y + flap);
        canvas.drawPath(path, birdPaint);
      }
    }

    // 5. HORIZON PEPOHONAN KAMPUS DI KEJAUHAN
    _drawDistantHorizon(canvas, w, baseY, n);

    // 6. GEDUNG REKTORAT UNESA LIDAH WETAN (3D PERSPEKTIF & BAYANGAN)
    _drawUnesaRectorateBuilding(canvas, w * 0.5, baseY, w, h, n);

    // 7. HAMPARAN LAPANGAN RUMPUT & JALAN SETAPAK PAVING
    final lawnPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.52, 1.0],
        colors: [
          _lerpRGB([126, 178, 92], [16, 44, 34], n),
          _lerpRGB([76, 150, 78], [11, 30, 26], n),
          _lerpRGB([38, 118, 68], [8, 20, 20], n),
        ],
      ).createShader(Rect.fromLTWH(0, baseY, w, h - baseY));
    canvas.drawRect(Rect.fromLTWH(0, baseY, w, h - baseY), lawnPaint);

    _drawLawnTexture(canvas, w, h, baseY, n);

    // Bayangan jatuh gedung rektorat di atas lapangan rumput
    final bShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.65, 1.0],
        colors: [
          n < 0.5 ? const Color(0x700C2416) : const Color(0x9E020610),
          n < 0.5 ? const Color(0x2E0E2A1A) : const Color(0x47030812),
          const Color(0x000F2A1A),
        ],
      ).createShader(Rect.fromLTWH(0, baseY, w, 42));
    final bShadowPath = Path()
      ..moveTo(w * 0.5 - 184, baseY)
      ..lineTo(w * 0.5 + 178, baseY)
      ..lineTo(w * 0.5 + 156, baseY + 40)
      ..lineTo(w * 0.5 - 208, baseY + 40)
      ..close();
    canvas.drawPath(bShadowPath, bShadowPaint);

    // Jalur setapak paving perspektif di tengah
    final pathPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _lerpRGB([232, 238, 245], [36, 48, 72], n),
          _lerpRGB([194, 204, 218], [22, 32, 50], n),
        ],
      ).createShader(Rect.fromLTWH(0, baseY, w, h - baseY));
    final walkPath = Path()
      ..moveTo(w * 0.5 - 16, baseY)
      ..lineTo(w * 0.5 + 16, baseY)
      ..lineTo(w * 0.5 + 36, h)
      ..lineTo(w * 0.5 - 36, h)
      ..close();
    canvas.drawPath(walkPath, pathPaint);

    // Kanstin paving kiri & kanan
    canvas.drawLine(
      Offset(w * 0.5 - 16, baseY),
      Offset(w * 0.5 - 36, h),
      Paint()
        ..color = _lerpRGB([148, 163, 184], [15, 23, 42], n)
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(w * 0.5 + 16, baseY),
      Offset(w * 0.5 + 36, h),
      Paint()
        ..color = _lerpRGB([255, 255, 255], [82, 102, 134], n)
        ..strokeWidth = 1.8,
    );

    final jointPaint = Paint()
      ..color = n < 0.5 ? const Color(0x3D64748B) : const Color(0x730F172A)
      ..strokeWidth = 0.8;
    for (double py = baseY + 6; py < h; py += 8) {
      final ratio = (py - baseY) / max(1.0, h - baseY);
      final halfW = 16.0 + ratio * 20.0;
      canvas.drawLine(Offset(w * 0.5 - halfW, py), Offset(w * 0.5 + halfW, py), jointPaint);
    }

    // 8. TERAS PLAZA BERUNDAK 3D, TUGU PRASASTI & TIANG BENDERA TENGAH
    _drawRectoratePlaza(canvas, w * 0.5, baseY, n);
    _drawCenterFlagpole(canvas, w * 0.5, baseY + 8 * scaleH, n);

    // 9. PEPOHONAN ORGANIK 3D REALISTIS DI SISI KIRI & KANAN
    final trees = [
      (x: 18.0, y: 310.0 * scaleH, trunkH: 52.0, s: 1.14, phase: 0.2, idx: 0),
      (x: 52.0, y: 305.0 * scaleH, trunkH: 40.0, s: 0.88, phase: 1.4, idx: 1),
      (x: 378.0, y: 305.0 * scaleH, trunkH: 40.0, s: 0.90, phase: 2.1, idx: 2),
      (x: 412.0, y: 310.0 * scaleH, trunkH: 52.0, s: 1.14, phase: 0.8, idx: 3),
    ];
    for (final t in trees) {
      final tx = (t.x / 430.0) * w;
      _drawOrganicTree(canvas, tx, t.y, t.trunkH, t.s, t.phase, treeCrowns[t.idx], n);
    }

    // 10. KUNANG-KUNANG MALAM
    if (n > 0.35) {
      for (int i = 0; i < 14; i++) {
        final phase = i * 1.1;
        final speed = 0.6 + (i % 4) * 0.15;
        final glow = 0.35 + 0.65 * sin(time * 3.1 + phase);
        final fx = (((i * 67) % 100) / 100.0) * w + sin(time * speed + phase) * 8;
        final fy = (0.78 + ((i * 29) % 18) / 100.0) * h + cos(time * speed + phase) * 4;
        canvas.drawCircle(
          Offset(fx, fy),
          1.8,
          Paint()..color = const Color(0xFFFDE047).withValues(alpha: n * glow * 0.85),
        );
      }
    }
  }

  void _drawLawnTexture(Canvas canvas, double w, double h, double topY, double n) {
    for (int row = 0; row < 5; row++) {
      final yPos = topY + 5 + row * 9;
      if (yPos > h) break;
      final alpha = (0.06 + row * 0.015) * (1 - n * 0.45);
      final p = Paint()
        ..color = row % 2 == 0
            ? const Color(0xFFDCFCE7).withValues(alpha: alpha)
            : const Color(0xFF0F3E22).withValues(alpha: (alpha * 1.4).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(w * 0.22, yPos);
      canvas.rotate(-0.02);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: (68 + row * 12) * 2, height: (2.4 + row * 0.4) * 2),
          p);
      canvas.restore();

      canvas.save();
      canvas.translate(w * 0.78, yPos + 2);
      canvas.rotate(0.02);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: (68 + row * 12) * 2, height: (2.4 + row * 0.4) * 2),
          p);
      canvas.restore();
    }

    final bladeDark = _lerpRGB([28, 96, 48], [6, 22, 18], n);
    final bladeLit = _lerpRGB([134, 212, 102], [20, 56, 42], n);
    for (int i = 0; i < 95; i++) {
      final rx = ((i * 97 + 13) % 100) / 100.0;
      final ry = ((i * 53 + 7) % 100) / 100.0;
      final gx = rx * w;
      if ((gx - w * 0.5).abs() < 22 + ry * 22) continue;
      final gy = topY + 3 + ry * (h - topY - 4);
      final depthScale = 0.45 + ry * 0.85;
      final wind = sin(time * 2.1 + gx * 0.04 + gy * 0.08) * 1.4 * depthScale;
      final bh = (3.2 + (i % 3) * 1.1) * depthScale;
      final paint = Paint()
        ..color = i % 2 == 0 ? bladeLit : bladeDark
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.85 * depthScale;
      final path = Path()
        ..moveTo(gx, gy)
        ..quadraticBezierTo(gx + wind * 0.5, gy - bh * 0.6, gx - 1.1 * depthScale + wind, gy - bh)
        ..moveTo(gx + 1.2 * depthScale, gy)
        ..quadraticBezierTo(
            gx + 1.2 * depthScale + wind * 0.6, gy - bh * 0.55, gx + 2.2 * depthScale + wind, gy - bh * 0.88);
      canvas.drawPath(path, paint);
    }
  }

  void _drawSoftCloud(Canvas canvas, double x, double y, double scale, double alpha, double n) {
    if (alpha <= 0.02) return;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    const puffs = [
      (dx: -24.0, dy: 4.0, r: 13.0),
      (dx: -10.0, dy: -2.0, r: 18.0),
      (dx: 8.0, dy: -7.0, r: 22.0),
      (dx: 26.0, dy: -1.0, r: 17.0),
      (dx: 39.0, dy: 5.0, r: 12.0),
      (dx: 6.0, dy: 6.0, r: 19.0),
    ];

    final underPath = Path();
    for (final p in puffs) {
      underPath.addOval(Rect.fromCircle(center: Offset(p.dx, p.dy + 3.5), radius: p.r));
    }
    canvas.drawPath(
      underPath,
      Paint()
        ..color = n < 0.5
            ? const Color(0xFF94B8E0).withValues(alpha: alpha * 0.52)
            : const Color(0xFF1E3056).withValues(alpha: alpha * 0.65),
    );

    final bodyPath = Path();
    for (final p in puffs) {
      bodyPath.addOval(Rect.fromCircle(center: Offset(p.dx, p.dy), radius: p.r));
    }
    final cloudPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: n < 0.5 ? const [0.0, 0.68, 1.0] : const [0.0, 1.0],
        colors: n < 0.5
            ? [
          Colors.white.withValues(alpha: alpha),
          const Color(0xFFF1F7FF).withValues(alpha: alpha * 0.96),
          const Color(0xFFCEE0F6).withValues(alpha: alpha * 0.90),
        ]
            : [
          const Color(0xFF94AED6).withValues(alpha: alpha * 0.78),
          const Color(0xFF384E7A).withValues(alpha: alpha * 0.72),
        ],
      ).createShader(const Rect.fromLTWH(-40, -28, 95, 50));
    canvas.drawPath(bodyPath, cloudPaint);

    if (n < 0.6) {
      final rimPath = Path()
        ..addArc(Rect.fromCircle(center: const Offset(10, -9), radius: 17), pi * 1.1, pi * 0.85)
        ..addArc(Rect.fromCircle(center: const Offset(27, -3), radius: 13), pi * 1.15, pi * 0.80);
      canvas.drawPath(
        rimPath,
        Paint()..color = Colors.white.withValues(alpha: alpha * (1 - n) * 0.55),
      );
    }
    canvas.restore();
  }

  void _drawDistantHorizon(Canvas canvas, double w, double baseY, double n) {
    final path = Path()..moveTo(0, baseY);
    for (double x = 0; x <= w + 22; x += 22) {
      final bushH = 12 + sin(x * 0.045) * 5 + cos(x * 0.11) * 3;
      path.lineTo(x, baseY - bushH);
    }
    path
      ..lineTo(w, baseY)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = _lerpRGB([134, 188, 148], [14, 34, 42], n),
    );
  }

  void _drawUnesaRectorateBuilding(
      Canvas canvas, double cx, double baseY, double w, double h, double n) {
    // Skala bangunan memperhitungkan tinggi kanvas sehingga atap limas & penangkal petir tidak pernah terpotong
    final maxAllowedScale = (baseY - 12.0) / 186.0;
    final scale = min(min(1.04, w / 415.0), maxAllowedScale);

    canvas.save();
    canvas.translate(cx, baseY);
    canvas.scale(scale, scale);

    final wallSunlit = _lerpRGB([254, 255, 255], [52, 72, 110], n);
    final wallWhite = _lerpRGB([238, 244, 251], [36, 52, 82], n);
    final wallShadow = _lerpRGB([186, 202, 224], [20, 31, 54], n);
    final wallDeepRecess = _lerpRGB([146, 166, 194], [13, 21, 38], n);
    final glassDeep = _lerpRGB([10, 76, 162], [14, 38, 84], n);
    final glassLight = _lerpRGB([72, 186, 252], [44, 98, 174], n);
    final roofLit = _lerpRGB([82, 64, 58], [26, 32, 52], n);
    final roofDark = _lerpRGB([44, 34, 32], [14, 18, 30], n);
    final terracottaLit = _lerpRGB([212, 90, 56], [118, 50, 40], n);
    final terracottaShade = _lerpRGB([148, 54, 34], [74, 30, 24], n);

    // --- A. SAYAP ATRIUM PENGHUBUNG ---
    canvas.drawRect(const Rect.fromLTWH(-108, -82, 216, 82), Paint()..color = wallDeepRecess);
    canvas.drawRect(const Rect.fromLTWH(-108, -82, 216, 9), Paint()..color = const Color(0x61081226));
    final atriumWinPaint = Paint()
      ..color = n > 0.4 ? const Color(0x94FDE082) : glassDeep;
    for (double wx = -98; wx <= 86; wx += 14) {
      if (wx.abs() > 54) {
        canvas.drawRect(Rect.fromLTWH(wx, -70, 9, 52), atriumWinPaint);
      }
    }

    // --- B. SAYAP SIMETRIS KIRI & KANAN ---
    for (final dir in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(dir, 1.0);

      final sidePath = Path()
        ..moveTo(176, -92)
        ..lineTo(186, -87)
        ..lineTo(186, 0)
        ..lineTo(176, 0)
        ..close();
      canvas.drawPath(sidePath, Paint()..color = dir == 1 ? wallSunlit : wallShadow);

      canvas.drawRect(
          const Rect.fromLTWH(64, -92, 112, 92), Paint()..color = dir == 1 ? wallSunlit : wallWhite);
      canvas.drawRect(const Rect.fromLTWH(64, -92, 16, 92), Paint()..color = wallShadow);

      final crownPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.55, 1.0],
          colors: [glassDeep, glassLight, glassDeep],
        ).createShader(const Rect.fromLTWH(64, -92, 112, 24));
      canvas.drawRect(const Rect.fromLTWH(64, -92, 112, 24), crownPaint);

      final mullionPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.36)
        ..strokeWidth = 0.85;
      canvas.drawLine(const Offset(64, -80), const Offset(176, -80), mullionPaint);
      for (double gx = 78; gx < 176; gx += 14) {
        canvas.drawLine(Offset(gx, -92), Offset(gx, -68), mullionPaint);
      }

      final wingRoofPath = Path()
        ..moveTo(61, -92)
        ..lineTo(120, -105)
        ..lineTo(187, -87)
        ..lineTo(176, -92)
        ..close();
      final wingRoofPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dir == 1 ? roofLit : roofDark,
            dir == 1 ? _lerpRGB([112, 86, 76], [34, 42, 68], n) : roofDark,
          ],
        ).createShader(const Rect.fromLTWH(61, -105, 126, 18));
      canvas.drawPath(wingRoofPath, wingRoofPaint);

      canvas.save();
      canvas.clipPath(wingRoofPath);
      final tileLinePaint = Paint()
        ..color = n < 0.5 ? Colors.white.withValues(alpha: 0.14) : const Color(0x1F94A3B8)
        ..strokeWidth = 0.7;
      for (double ry = -103; ry <= -88; ry += 2.6) {
        canvas.drawLine(Offset(60, ry), Offset(188, ry + 3.5), tileLinePaint);
      }
      canvas.restore();

      canvas.drawLine(
        const Offset(120, -105),
        const Offset(176, -92),
        Paint()
          ..color = dir == 1 ? const Color(0x6BFFF4E6) : Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 1.1,
      );
      canvas.drawRect(
          const Rect.fromLTWH(61, -93.2, 115, 1.8), Paint()..color = dir == 1 ? wallSunlit : wallWhite);

      canvas.drawRect(const Rect.fromLTWH(82, -64, 84, 56), Paint()..color = glassDeep);
      if (n > 0.35) {
        canvas.drawRect(
          const Rect.fromLTWH(86, -58, 76, 44),
          Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.44 * n),
        );
      }

      final cornicePaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x85081226), Color(0x00081226)],
        ).createShader(const Rect.fromLTWH(78, -68, 92, 14));
      canvas.drawRect(const Rect.fromLTWH(78, -68, 92, 14), cornicePaint);

      for (final px in [78.0, 97.0, 116.0, 135.0, 154.0]) {
        canvas.drawRect(
          Rect.fromLTWH(px + (dir == 1 ? -4.5 : 5.5), -66, 5, 66),
          Paint()..color = const Color(0x570A162E),
        );
        final pPaint = Paint()
          ..shader = LinearGradient(
            stops: const [0.0, 0.55, 1.0],
            colors: [
              dir == 1 ? wallShadow : wallSunlit,
              wallWhite,
              dir == 1 ? wallSunlit : wallDeepRecess,
            ],
          ).createShader(Rect.fromLTWH(px, -68, 7, 68));
        canvas.drawRect(Rect.fromLTWH(px, -68, 7, 68), pPaint);
        canvas.drawRect(Rect.fromLTWH(px - 1, -68, 9, 3), Paint()..color = wallSunlit);
        canvas.drawRect(Rect.fromLTWH(px - 1, -3, 9, 3), Paint()..color = wallSunlit);
      }

      canvas.drawRect(const Rect.fromLTWH(104, -22, 34, 22), Paint()..color = wallWhite);
      canvas.drawRect(const Rect.fromLTWH(104, -20.5, 34, 4.5), Paint()..color = const Color(0x6B081226));
      canvas.drawRect(const Rect.fromLTWH(101, -24.5, 40, 4), Paint()..color = wallSunlit);

      canvas.restore();
    }

    // --- C. MENARA UTAMA REKTORAT DI TENGAH ---
    final towerLeftShadow = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x7A081226), Color(0x00081226)],
      ).createShader(const Rect.fromLTWH(-78, -92, 24, 92));
    canvas.drawRect(const Rect.fromLTWH(-78, -92, 24, 92), towerLeftShadow);

    final towerRightAO = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x3D081226), Color(0x00081226)],
      ).createShader(const Rect.fromLTWH(54, -92, 12, 92));
    canvas.drawRect(const Rect.fromLTWH(54, -92, 12, 92), towerRightAO);

    final leftExtrude = Path()
      ..moveTo(-55, -160)
      ..lineTo(-62, -157)
      ..lineTo(-62, -92)
      ..lineTo(-55, -92)
      ..close();
    canvas.drawPath(leftExtrude, Paint()..color = wallShadow);

    final leftRoofPath = Path()
      ..moveTo(-63, -157)
      ..lineTo(0, -176)
      ..lineTo(0, -160)
      ..lineTo(-55, -160)
      ..close();
    canvas.drawPath(
      leftRoofPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [roofDark, _lerpRGB([68, 54, 50], [22, 28, 46], n)],
        ).createShader(const Rect.fromLTWH(-63, -176, 63, 19)),
    );

    final rightRoofPath = Path()
      ..moveTo(0, -176)
      ..lineTo(61, -160)
      ..lineTo(0, -160)
      ..close();
    canvas.drawPath(
      rightRoofPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lerpRGB([118, 90, 78], [38, 48, 76], n), roofLit],
        ).createShader(const Rect.fromLTWH(0, -176, 61, 16)),
    );

    final fullRoofClip = Path()
      ..moveTo(-63, -157)
      ..lineTo(0, -176)
      ..lineTo(61, -160)
      ..lineTo(-55, -160)
      ..close();
    canvas.save();
    canvas.clipPath(fullRoofClip);
    final hShingle = Paint()
      ..color = n < 0.5 ? const Color(0x29FFF8F0) : const Color(0x2494A3B8)
      ..strokeWidth = 0.75;
    for (double ty = -174; ty <= -160; ty += 2.5) {
      canvas.drawLine(Offset(-64, ty), Offset(62, ty), hShingle);
    }
    final vSeam = Paint()
      ..color = const Color(0x380F0C0C)
      ..strokeWidth = 0.75;
    for (double tx = -56; tx <= 56; tx += 7) {
      canvas.drawLine(const Offset(0, -176), Offset(tx, -159), vSeam);
    }
    canvas.restore();

    final ridgePaint = Paint()
      ..color = n < 0.5 ? const Color(0x8CFFF4E4) : const Color(0x59BAD2FF)
      ..strokeWidth = 1.25;
    canvas.drawLine(const Offset(0, -176), const Offset(0, -160), ridgePaint);
    canvas.drawLine(const Offset(0, -176), const Offset(61, -160), ridgePaint);

    canvas.drawLine(
      const Offset(0, -176),
      const Offset(0, -182),
      Paint()
        ..color = _lerpRGB([226, 232, 240], [148, 163, 184], n)
        ..strokeWidth = 1.3,
    );
    canvas.drawCircle(const Offset(0, -182.5), 1.4, Paint()..color = const Color(0xFFF59E0B));

    canvas.drawRect(const Rect.fromLTWH(-56, -161.2, 117, 2.2), Paint()..color = wallSunlit);
    canvas.drawRect(
      const Rect.fromLTWH(-55, -160, 110, 160),
      Paint()
        ..shader = LinearGradient(
          stops: const [0.0, 0.45, 1.0],
          colors: [wallShadow, wallWhite, wallSunlit],
        ).createShader(const Rect.fromLTWH(-56, -160, 112, 160)),
    );

    canvas.drawRect(
      const Rect.fromLTWH(-55, -160, 110, 12),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x85081226), Color(0x00081226)],
        ).createShader(const Rect.fromLTWH(-55, -160, 110, 12)),
    );

    canvas.drawRect(const Rect.fromLTWH(-55, -160, 14, 160), Paint()..color = wallShadow);
    canvas.drawRect(const Rect.fromLTWH(-41, -160, 2.5, 160), Paint()..color = wallDeepRecess);
    canvas.drawRect(const Rect.fromLTWH(41, -160, 14, 160), Paint()..color = wallSunlit);
    canvas.drawRect(const Rect.fromLTWH(39, -160, 2.2, 160), Paint()..color = wallShadow);

    for (double wy = -150; wy <= -26; wy += 12) {
      canvas.drawRect(Rect.fromLTWH(-50, wy - 0.8, 6, 8.2), Paint()..color = wallDeepRecess);
      canvas.drawRect(Rect.fromLTWH(43, wy - 0.8, 6, 8.2), Paint()..color = wallDeepRecess);
      final winColor = n > 0.4 ? const Color(0xB8FDE082) : glassDeep;
      canvas.drawRect(Rect.fromLTWH(-49, wy, 5, 7), Paint()..color = winColor);
      canvas.drawRect(Rect.fromLTWH(44, wy, 5, 7), Paint()..color = winColor);
    }

    final towerGlassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.55, 1.0],
        colors: [glassDeep, glassLight, glassDeep],
      ).createShader(const Rect.fromLTWH(-38, -154, 76, 126));
    canvas.drawRect(const Rect.fromLTWH(-38, -154, 31, 124), towerGlassPaint);
    canvas.drawRect(const Rect.fromLTWH(7, -154, 31, 124), towerGlassPaint);

    final glassShadow = Paint()..color = const Color(0x61081228);
    canvas.drawRect(const Rect.fromLTWH(-10.5, -154, 3.5, 124), glassShadow);
    canvas.drawRect(const Rect.fromLTWH(34.5, -154, 3.5, 124), glassShadow);
    canvas.drawRect(const Rect.fromLTWH(-38, -154, 31, 4), glassShadow);
    canvas.drawRect(const Rect.fromLTWH(7, -154, 31, 4), glassShadow);

    if (n < 0.7) {
      final shimmerOffset = sin(time * 0.9) * 10;
      final shimmerPath = Path()
        ..moveTo(7, -125 + shimmerOffset)
        ..lineTo(38, -145 + shimmerOffset)
        ..lineTo(38, -133 + shimmerOffset)
        ..lineTo(7, -113 + shimmerOffset)
        ..close();
      canvas.drawPath(
        shimmerPath,
        Paint()..color = Colors.white.withValues(alpha: (1 - n) * 0.22),
      );
    }

    if (n > 0.25) {
      final nightWin = Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.5 * n);
      for (double ry = -146; ry <= -38; ry += 16) {
        canvas.drawRect(Rect.fromLTWH(-34, ry, 10, 7), nightWin);
        canvas.drawRect(Rect.fromLTWH(-20, ry, 10, 7), nightWin);
        canvas.drawRect(Rect.fromLTWH(10, ry, 10, 7), nightWin);
        canvas.drawRect(Rect.fromLTWH(24, ry, 10, 7), nightWin);
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..strokeWidth = 0.75;
    for (double gy = -144; gy <= -34; gy += 12) {
      canvas.drawLine(Offset(-38, gy), Offset(-7, gy), gridPaint);
      canvas.drawLine(Offset(7, gy), Offset(38, gy), gridPaint);
    }

    canvas.drawRect(const Rect.fromLTWH(-11, -156, 3, 126), Paint()..color = const Color(0x57081228));
    canvas.drawRect(
      const Rect.fromLTWH(-8, -156, 16, 126),
      Paint()
        ..shader = LinearGradient(
          stops: const [0.0, 0.5, 1.0],
          colors: [wallShadow, wallWhite, wallSunlit],
        ).createShader(const Rect.fromLTWH(-8, -156, 16, 126)),
    );

    for (double sy = -112; sy <= -38; sy += 13) {
      canvas.drawRect(Rect.fromLTWH(-4.8, sy - 0.7, 9.6, 9), Paint()..color = wallDeepRecess);
      canvas.drawRect(
        Rect.fromLTWH(-4.2, sy, 8.4, 8),
        Paint()..color = n > 0.4 ? const Color(0xBDFDE082) : glassDeep,
      );
    }

    // Plakat Logo UNESA di Menara Tengah
    canvas.drawRect(const Rect.fromLTWH(-17.5, -152, 31, 36.5), Paint()..color = const Color(0x75081228));
    canvas.drawRect(const Rect.fromLTWH(-15, -154, 30, 36), Paint()..color = const Color(0xFF0B357A));
    canvas.drawRect(
      const Rect.fromLTWH(-15, -154, 30, 36),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    _drawUnesaCrestEmblem(canvas, 0, -138, 12.2);

    canvas.drawRect(const Rect.fromLTWH(-38, -32, 2.5, 32), Paint()..color = terracottaShade);
    canvas.drawRect(const Rect.fromLTWH(-35.5, -32, 10.5, 32), Paint()..color = terracottaLit);
    canvas.drawRect(const Rect.fromLTWH(25, -32, 2.5, 32), Paint()..color = terracottaShade);
    canvas.drawRect(const Rect.fromLTWH(27.5, -32, 10.5, 32), Paint()..color = terracottaLit);

    canvas.drawRect(const Rect.fromLTWH(-47, -15, 93, 6.5), Paint()..color = const Color(0x7A081226));
    canvas.drawRect(const Rect.fromLTWH(-48, -19.5, 96, 4.5), Paint()..color = wallSunlit);
    canvas.drawRect(const Rect.fromLTWH(-48, -16, 96, 1.5), Paint()..color = wallShadow);
    canvas.drawRect(const Rect.fromLTWH(-16, -15, 32, 5.5), Paint()..color = const Color(0xFFB91C1C));
    canvas.drawRect(const Rect.fromLTWH(-24, -10, 48, 10), Paint()..color = wallDeepRecess);

    if (n > 0.3) {
      final upGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, 0.65),
          radius: 0.9,
          colors: [
            const Color(0xFFFDE082).withValues(alpha: 0.28 * n),
            const Color(0xFFFDE082).withValues(alpha: 0.0),
          ],
        ).createShader(const Rect.fromLTWH(-160, -170, 320, 170));
      canvas.drawRect(const Rect.fromLTWH(-160, -170, 320, 170), upGlow);
    }

    canvas.restore();
  }

  /// Logo UNESA lengkap (Tugu Pahlawan emas berlekuk + 9 helai sayap melengkung + tulisan UNESA)
  void _drawUnesaCrestEmblem(Canvas canvas, double cx, double cy, double r) {
    canvas.save();
    canvas.translate(cx, cy - 0.8);
    final s = r / 12.0;
    canvas.scale(s, s);

    // 1. Tugu Pahlawan Emas di Tengah
    final tuguOuter = Path()
      ..moveTo(0, -11.2)
      ..quadraticBezierTo(1.2, -9.8, 1.3, -9.0)
      ..lineTo(2.3, 5.4)
      ..lineTo(0, 6.4)
      ..lineTo(-2.3, 5.4)
      ..lineTo(-1.3, -9.0)
      ..quadraticBezierTo(-1.2, -9.8, 0, -11.2)
      ..close();
    canvas.drawPath(tuguOuter, Paint()..color = const Color(0xFFD4AF37));

    // Alur vertikal tugu
    final flutePaint = Paint()
      ..color = const Color(0xFF0B357A)
      ..strokeWidth = 0.52;
    canvas.drawLine(const Offset(-0.75, -8.2), const Offset(-1.05, 5.1), flutePaint);
    canvas.drawLine(const Offset(0.0, -8.5), const Offset(0.0, 5.5), flutePaint);
    canvas.drawLine(const Offset(0.75, -8.2), const Offset(1.05, 5.1), flutePaint);

    // 2. Pangkal Sayap Menyatu di Bawah Tugu
    final baseWing = Path()
      ..moveTo(0, 8.2)
      ..quadraticBezierTo(-3.2, 6.2, -6.8, 7.6)
      ..quadraticBezierTo(-3.6, 4.4, 0, 5.8)
      ..quadraticBezierTo(3.6, 4.4, 6.8, 7.6)
      ..quadraticBezierTo(3.2, 6.2, 0, 8.2)
      ..close();
    canvas.drawPath(baseWing, Paint()..color = const Color(0xFFD4AF37));

    // 3. Helai Bulu Sayap Emas Melengkung Simetris Kiri & Kanan
    final featherPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    for (final dir in [-1.0, 1.0]) {
      for (int i = 0; i < 8; i++) {
        final t = i / 7.0;
        final sx = dir * (2.6 + t * 2.4);
        final sy = -3.8 + t * 9.6;
        final tx = dir * (5.2 + sin(t * 2.5) * 5.8);
        final ty = -9.6 + t * 14.5;
        final cx1 = dir * (4.2 + sin(t * 2.3) * 4.8);
        final cy1 = -7.8 + t * 11.2;

        final feather = Path()
          ..moveTo(sx, sy)
          ..quadraticBezierTo(cx1, cy1 - 1.1, tx, ty)
          ..quadraticBezierTo(cx1 - dir * 0.5, cy1 + 0.9, sx, sy + 1.15)
          ..close();
        canvas.drawPath(feather, featherPaint);
      }
    }

    // 4. Tulisan "UNESA" Emas di Bawah Sayap
    final tp = TextPainter(
      text: const TextSpan(
        text: 'UNESA',
        style: TextStyle(
          color: Color(0xFFEAB308),
          fontSize: 4.1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 8.8));

    canvas.restore();
  }

  void _drawRectoratePlaza(Canvas canvas, double cx, double baseY, double n) {
    final treadLit = _lerpRGB([244, 248, 253], [52, 68, 96], n);
    final riserShade = _lerpRGB([178, 194, 214], [24, 34, 56], n);
    final bushColor = _lerpRGB([34, 139, 68], [12, 46, 36], n);

    for (final dir in [-1.0, 1.0]) {
      for (int step = 0; step < 3; step++) {
        final sy = baseY - 6 + step * 3.2;
        final sx = dir == 1 ? cx + 28 : cx - 158;
        canvas.drawRect(Rect.fromLTWH(sx, sy, 130, 1.8), Paint()..color = treadLit);
        canvas.drawRect(Rect.fromLTWH(sx, sy + 1.8, 130, 1.4), Paint()..color = riserShade);
      }
      final bx = dir == 1 ? cx + 44 : cx - 144;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, baseY - 8.5, 100, 4.5), const Radius.circular(2)),
        Paint()..color = bushColor,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(cx - 24, baseY - 8, 48, 9),
      Paint()..color = _lerpRGB([51, 65, 85], [15, 23, 42], n),
    );
    canvas.drawRect(
        Rect.fromLTWH(cx - 16, baseY - 5.2, 32, 2.2), Paint()..color = const Color(0xFFF59E0B));
  }

  void _drawCenterFlagpole(Canvas canvas, double cx, double baseY, double n) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 5, baseY + 2.2), width: 32, height: 7.2),
      Paint()..color = n < 0.5 ? const Color(0x660C2416) : const Color(0x99020610),
    );

    canvas.drawLine(
      Offset(cx - 2, baseY + 1),
      Offset(cx - 34, baseY + 14),
      Paint()
        ..shader = LinearGradient(
          colors: [
            n < 0.5 ? const Color(0x4D0C2416) : const Color(0x70020610),
            const Color(0x000C2416),
          ],
        ).createShader(Rect.fromPoints(Offset(cx - 2, baseY + 1), Offset(cx - 34, baseY + 14)))
        ..strokeWidth = 2.6,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + 1.8), width: 28, height: 7.0),
      Paint()..color = _lerpRGB([186, 200, 218], [44, 58, 82], n),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + 0.5), width: 28, height: 6.4),
      Paint()..color = _lerpRGB([252, 254, 255], [148, 163, 184], n),
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - 3.5, baseY - 5, 7, 6),
      Paint()
        ..shader = LinearGradient(
          colors: [
            _lerpRGB([148, 163, 184], [51, 65, 85], n),
            _lerpRGB([255, 255, 255], [148, 163, 184], n),
          ],
        ).createShader(Rect.fromLTWH(cx - 3.5, baseY - 5, 7, 6)),
    );

    final poleTopY = baseY - 118;
    canvas.drawLine(
      Offset(cx - 0.5, baseY - 4),
      Offset(cx - 0.5, poleTopY),
      Paint()
        ..color = _lerpRGB([134, 150, 172], [64, 78, 98], n)
        ..strokeWidth = 2.4,
    );
    canvas.drawLine(
      Offset(cx + 0.4, baseY - 4),
      Offset(cx + 0.4, poleTopY),
      Paint()
        ..color = _lerpRGB([255, 255, 255], [203, 213, 225], n)
        ..strokeWidth = 1.1,
    );
    canvas.drawCircle(Offset(cx, poleTopY - 1.5), 2.5, Paint()..color = const Color(0xFFF59E0B));

    const flagW = 24.0;
    const flagH = 14.0;
    final wave1 = sin(time * 4.2) * 2.2;
    final wave2 = cos(time * 4.2 - 1.2) * 2.8;

    final redPath = Path()
      ..moveTo(cx + 1, poleTopY + 2)
      ..cubicTo(
        cx + 1 + flagW * 0.4,
        poleTopY + 2 + wave1,
        cx + 1 + flagW * 0.7,
        poleTopY + 2 - wave1,
        cx + 1 + flagW,
        poleTopY + 2 + wave2,
      )
      ..lineTo(cx + 1 + flagW, poleTopY + 2 + flagH * 0.5 + wave2)
      ..cubicTo(
        cx + 1 + flagW * 0.7,
        poleTopY + 2 + flagH * 0.5 - wave1,
        cx + 1 + flagW * 0.4,
        poleTopY + 2 + flagH * 0.5 + wave1,
        cx + 1,
        poleTopY + 2 + flagH * 0.5,
      )
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFDC2626));

    final whitePath = Path()
      ..moveTo(cx + 1, poleTopY + 2 + flagH * 0.5)
      ..cubicTo(
        cx + 1 + flagW * 0.4,
        poleTopY + 2 + flagH * 0.5 + wave1,
        cx + 1 + flagW * 0.7,
        poleTopY + 2 + flagH * 0.5 - wave1,
        cx + 1 + flagW,
        poleTopY + 2 + flagH * 0.5 + wave2,
      )
      ..lineTo(cx + 1 + flagW, poleTopY + 2 + flagH + wave2)
      ..cubicTo(
        cx + 1 + flagW * 0.7,
        poleTopY + 2 + flagH - wave1,
        cx + 1 + flagW * 0.4,
        poleTopY + 2 + flagH + wave1,
        cx + 1,
        poleTopY + 2 + flagH,
      )
      ..close();
    canvas.drawPath(
      whitePath,
      Paint()..color = _lerpRGB([255, 255, 255], [226, 232, 240], n),
    );
  }

  void _drawOrganicTree(
      Canvas canvas,
      double x,
      double y,
      double trunkH,
      double s,
      double phase,
      List<_LeafSpray> crown,
      double n,
      ) {
    final sway = sin(time * 1.45 + phase) * 1.6;
    canvas.save();
    canvas.translate(x, y);

    final treeShadow = Paint()
      ..shader = RadialGradient(
        colors: [
          n < 0.5 ? const Color(0x6B0A2214) : const Color(0x9E020610),
          n < 0.5 ? const Color(0x380C2616) : const Color(0x57030812),
          const Color(0x000C2616),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(-10 * s, 3), radius: 34 * s));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-10 * s, 3), width: 68 * s, height: 13.6 * s),
      treeShadow,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1.5), width: 26 * s, height: 7.2 * s),
      Paint()..color = n < 0.5 ? const Color(0x8A081C10) : const Color(0xB802050C),
    );

    final barkDark = _lerpRGB([56, 38, 30], [18, 14, 16], n);
    final barkMid = _lerpRGB([96, 68, 50], [32, 25, 28], n);
    final barkRim = _lerpRGB([144, 108, 82], [52, 42, 46], n);
    final trunkPath = Path()
      ..moveTo(-5.8 * s, 1.5)
      ..quadraticBezierTo(-2.3 * s, -4 * s, -2.0 * s, -trunkH * 0.4)
      ..quadraticBezierTo(-1.4 * s, -trunkH * 0.75, sway * 0.5 - 1.2 * s, -trunkH * 0.92)
      ..lineTo(sway * 0.5 + 1.2 * s, -trunkH * 0.92)
      ..quadraticBezierTo(1.4 * s, -trunkH * 0.75, 2.0 * s, -trunkH * 0.4)
      ..quadraticBezierTo(2.3 * s, -4 * s, 5.8 * s, 1.5)
      ..close();
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = LinearGradient(
          stops: const [0.0, 0.55, 1.0],
          colors: [barkDark, barkMid, barkRim],
        ).createShader(Rect.fromLTWH(-5 * s, -trunkH, 10 * s, trunkH)),
    );

    final branchPaint = Paint()
      ..color = barkMid
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2 * s;
    final bPath = Path()
      ..moveTo(sway * 0.38, -trunkH * 0.66)
      ..quadraticBezierTo(
          sway * 0.55 - 8 * s, -trunkH * 0.80, sway * 0.75 - 19 * s, -trunkH - 8 * s)
      ..moveTo(sway * 0.40, -trunkH * 0.70)
      ..quadraticBezierTo(
          sway * 0.58 + 8 * s, -trunkH * 0.84, sway * 0.75 + 18 * s, -trunkH - 7 * s)
      ..moveTo(sway * 0.48, -trunkH * 0.84)
      ..quadraticBezierTo(
          sway * 0.68 - 5 * s, -trunkH - 6 * s, sway * 0.88 - 11 * s, -trunkH - 24 * s)
      ..moveTo(sway * 0.48, -trunkH * 0.86)
      ..quadraticBezierTo(
          sway * 0.70 + 5 * s, -trunkH - 8 * s, sway * 0.90 + 10 * s, -trunkH - 25 * s);
    canvas.drawPath(bPath, branchPaint);

    final deepShade = _lerpRGB([16, 68, 36], [5, 20, 17], n);
    final midShade = _lerpRGB([30, 112, 56], [9, 34, 28], n);
    final midFoliage = _lerpRGB([48, 154, 78], [14, 52, 40], n);
    final upperFoliage = _lerpRGB([84, 188, 98], [22, 72, 52], n);
    final sunTip = _lerpRGB([154, 230, 128], [34, 96, 68], n);

    canvas.translate(sway, -trunkH + 2);
    for (int layer = 0; layer <= 3; layer++) {
      for (final leaf in crown) {
        if (leaf.layer != layer) continue;
        canvas.save();
        canvas.translate(leaf.x, leaf.y);
        canvas.rotate(leaf.rot);

        if (layer >= 1) {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(-0.9 * s, 1.3 * s), width: leaf.len * 2, height: leaf.wid * 2),
            Paint()..color = deepShade,
          );
        }

        Color leafColor;
        if (layer == 0) {
          leafColor = leaf.sunExposure > 0.2 ? midShade : deepShade;
        } else if (layer == 1) {
          leafColor = leaf.sunExposure > 0.25 ? midFoliage : midShade;
        } else if (layer == 2) {
          leafColor = leaf.sunExposure > 0.35 ? upperFoliage : midFoliage;
        } else {
          leafColor = leaf.sunExposure > 0.2 ? sunTip : upperFoliage;
        }

        final lp = Paint()..color = leafColor;
        canvas.save();
        canvas.rotate(-0.25);
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: leaf.len * 2, height: leaf.wid * 2), lp);
        canvas.restore();

        canvas.save();
        canvas.translate(leaf.len * 0.35, -leaf.wid * 0.45);
        canvas.rotate(0.35);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: leaf.len * 1.64, height: leaf.wid * 1.70),
            lp);
        canvas.restore();

        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CampusAtmospherePainter old) =>
      old.time != time || old.night != night;
}

// ------------------------------------------------------------------ header halaman lain (seragam dengan beranda)
class BandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double? height;

  const BandHeader(this.title, {super.key, this.subtitle, this.trailing, this.height});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return CartoonHeader(
      height: height ?? 132,
      sunX: .86,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                  const Color(0xFF070E1E).withValues(alpha: 0.62),
                  const Color(0xFF0B1730).withValues(alpha: 0.45),
                ]
                    : [
                  const Color(0xFF0E74D6).withValues(alpha: 0.22),
                  const Color(0xFF093275).withValues(alpha: 0.36),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 16, 16),
              child: Row(
                children: [
                  const AppLogo(size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.68)
                                : Colors.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: dark ? Colors.white : const Color(0xFF0B357A),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: dark ? Colors.white70 : const Color(0xFF475569),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}