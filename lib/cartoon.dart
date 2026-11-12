import 'dart:math';
import 'package:flutter/material.dart';
import 'core.dart';

/// Ilustrasi kartun gedung Rektorat UNESA: menara kaca biru tengah dengan lambang emas,
/// sayap kaca di kiri-kanan, bendera, pohon rindang, jalan, awan, dan burung.
/// Otomatis berubah suasana malam saat tema gelap.
class CampusPainter extends CustomPainter {
  final bool night;
  final double bx, bs, sunX, groundY;
  const CampusPainter({this.night = false, this.bx = .5, this.bs = .5, this.sunX = .88, this.groundY = .88});

  void _cloud(Canvas c, Offset o, double s, Paint p) {
    c.drawCircle(o, s, p);
    c.drawCircle(o + Offset(s, s * .2), s * .8, p);
    c.drawCircle(o + Offset(-s, s * .25), s * .7, p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, s * .55), width: s * 3.2, height: s * .9), Radius.circular(s * .45)), p);
  }

  void _tree(Canvas c, Offset b, double s) {
    c.drawRect(Rect.fromLTWH(b.dx - s * .05, b.dy - s * .45, s * .1, s * .45), Paint()..color = const Color(0xFF7B5B3A));
    final dark = Paint()..color = night ? const Color(0xFF1A5C3C) : const Color(0xFF2A9D5C);
    final mid = Paint()..color = night ? const Color(0xFF237A4D) : const Color(0xFF3FBF73);
    final light = Paint()..color = night ? const Color(0xFF2E9A60) : const Color(0xFF6AD895);
    c.drawCircle(b + Offset(0, -s * .75), s * .36, dark);
    c.drawCircle(b + Offset(-s * .3, -s * .55), s * .28, dark);
    c.drawCircle(b + Offset(s * .3, -s * .55), s * .28, dark);
    c.drawCircle(b + Offset(-s * .05, -s * .85), s * .26, mid);
    c.drawCircle(b + Offset(s * .15, -s * .7), s * .18, light);
  }

  void _bird(Canvas c, Offset o, double s, Paint p) {
    final path = Path()
      ..moveTo(o.dx - s, o.dy)
      ..quadraticBezierTo(o.dx - s * .5, o.dy - s * .8, o.dx, o.dy)
      ..quadraticBezierTo(o.dx + s * .5, o.dy - s * .8, o.dx + s, o.dy);
    c.drawPath(path, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // langit
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .55, 1],
          colors: night ? const [Color(0xFF0A1F3D), Color(0xFF173B5C), Color(0xFF1D4E5C)] : const [Color(0xFF2F9BE3), Color(0xFF8ED2F6), Color(0xFFE0F5EF)],
        ).createShader(rect),
    );
    if (night) {
      final sp = Paint()..color = Colors.white70;
      for (var i = 0; i < 18; i++) {
        canvas.drawCircle(Offset(w * ((i * 37) % 100) / 100, h * ((i * 53) % 45) / 100), 1.2, sp);
      }
    }

    // matahari / bulan
    final sc = Offset(w * sunX, h * .2);
    canvas.drawCircle(sc, h * .13, Paint()..color = (night ? Colors.white : const Color(0xFFFFF3B0)).withValues(alpha: .28));
    canvas.drawCircle(sc, h * .075, Paint()..color = night ? const Color(0xFFF1EEC9) : const Color(0xFFFFE066));

    // awan
    final cp = Paint()..color = Colors.white.withValues(alpha: night ? .12 : .9);
    _cloud(canvas, Offset(w * .22, h * .3), h * .055, cp);
    _cloud(canvas, Offset(w * .72, h * .13), h * .045, cp);
    _cloud(canvas, Offset(w * .93, h * .36), h * .04, cp);

    // bukit
    final back = Path()
      ..moveTo(0, h * .74)
      ..quadraticBezierTo(w * .25, h * .6, w * .5, h * .72)
      ..quadraticBezierTo(w * .78, h * .84, w, h * .66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = night ? const Color(0xFF14503A) : const Color(0xFF86D3A0));
    final front = Path()
      ..moveTo(0, h * .84)
      ..quadraticBezierTo(w * .3, h * .76, w * .6, h * .86)
      ..quadraticBezierTo(w * .85, h * .93, w, h * .8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = night ? const Color(0xFF0E3B2B) : const Color(0xFF4CBF7A));

    // ukuran gedung
    final u = min(w, h * 1.4);
    final bh = u * bs;
    final cx = w * bx;
    final base = h * groundY;
    final tH = bh * .78, tW = bh * .34;
    final wH = tH * .6, wW = bh * .3;
    final oH = tH * .38, oW = bh * .26;

    // jalan
    canvas.drawPath(
      Path()
        ..moveTo(cx - tW * .3, base)
        ..lineTo(cx + tW * .3, base)
        ..lineTo(cx + w * .45, h)
        ..lineTo(cx - w * .45, h)
        ..close(),
      Paint()..color = night ? const Color(0xFF2B3A46) : const Color(0xFF9AA6B2),
    );
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y1 = base + (h - base) * (.12 + i * .3), y2 = y1 + (h - base) * .14;
      dash.strokeWidth = 1.5 + i * 1.5;
      canvas.drawLine(Offset(cx, y1), Offset(cx, y2), dash);
    }

    // kaca bergaris
    final frame = Paint()..color = night ? const Color(0xFFDCE8F0) : Colors.white;
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..strokeWidth = 1;
    void glass(Rect r, int cols, int rows) {
      canvas.drawRect(r, frame);
      final g = r.deflate(max(2.0, r.width * .04));
      canvas.drawRect(
        g,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4FA3EE), Color(0xFF1F5FB5)]).createShader(g),
      );
      for (var i = 1; i < cols; i++) {
        final x = g.left + g.width * i / cols;
        canvas.drawLine(Offset(x, g.top), Offset(x, g.bottom), grid);
      }
      for (var j = 1; j < rows; j++) {
        final y = g.top + g.height * j / rows;
        canvas.drawLine(Offset(g.left, y), Offset(g.right, y), grid);
      }
    }

    glass(Rect.fromLTWH(cx - tW / 2 - wW - oW, base - oH, oW, oH), 3, 4);
    glass(Rect.fromLTWH(cx + tW / 2 + wW, base - oH, oW, oH), 3, 4);
    glass(Rect.fromLTWH(cx - tW / 2 - wW, base - wH, wW, wH), 4, 7);
    glass(Rect.fromLTWH(cx + tW / 2, base - wH, wW, wH), 4, 7);
    glass(Rect.fromLTWH(cx - tW / 2, base - tH, tW, tH), 4, 12);

    // atap menara, lambang emas, pintu
    canvas.drawRect(Rect.fromLTWH(cx - tW / 2 - 3, base - tH - 5, tW + 6, 6), Paint()..color = const Color(0xFFE6ECF2));
    final pl = Rect.fromCenter(center: Offset(cx, base - tH * .72), width: tW * .44, height: tH * .2);
    canvas.drawRRect(RRect.fromRectAndRadius(pl, const Radius.circular(3)), Paint()..color = const Color(0xFF1B3F8B));
    canvas.drawCircle(pl.center, min(pl.width, pl.height) * .34, Paint()..color = const Color(0xFFF2C230));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, base - tH * .1), width: tW * .8, height: 4), frame);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, base - tH * .045), width: tW * .5, height: tH * .09), Paint()..color = const Color(0xFF173F7A));

    // bendera merah putih
    final px = cx + tW / 2 + wW * .55, pb = base - wH, pt = pb - bh * .3;
    canvas.drawLine(Offset(px, pb), Offset(px, pt), Paint()..color = const Color(0xFF8A97A3)..strokeWidth = 2);
    canvas.drawRect(Rect.fromLTWH(px, pt, bh * .12, bh * .04), Paint()..color = const Color(0xFFE53935));
    canvas.drawRect(Rect.fromLTWH(px, pt + bh * .04, bh * .12, bh * .04), Paint()..color = Colors.white);

    // semak
    final bush = Paint()..color = night ? const Color(0xFF1F6B45) : const Color(0xFF2A9D5C);
    for (var i = -5; i <= 5; i++) {
      if (i.abs() < 2) continue;
      canvas.drawCircle(Offset(cx + i * bh * .16, base + 1), bh * .045, bush);
    }

    // pohon
    final ts = min(h * .4, w * .38);
    _tree(canvas, Offset(w * .07, base + (h - base) * .55), ts);
    _tree(canvas, Offset(w * .94, base + (h - base) * .5), ts * .9);

    // burung
    final bp = Paint()
      ..color = (night ? Colors.white : const Color(0xFF455A64)).withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    _bird(canvas, Offset(w * .46, h * .22), h * .028, bp);
    _bird(canvas, Offset(w * .52, h * .17), h * .022, bp);
  }

  @override
  bool shouldRepaint(CampusPainter o) => o.night != night || o.bx != bx || o.bs != bs || o.sunX != sunX || o.groundY != groundY;
}

/// Pita ilustrasi di atas layar (sudut bawah membulat) + konten di atasnya.
class CartoonHeader extends StatelessWidget {
  final double height, bx, bs, sunX, groundY;
  final Widget? child;
  const CartoonHeader({super.key, this.height = 200, this.bx = .8, this.bs = .5, this.sunX = .9, this.groundY = .9, this.child});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        CustomPaint(painter: CampusPainter(night: isDark(context), bx: bx, bs: bs, sunX: sunX, groundY: groundY)),
        if (child != null) child!,
      ]),
    ),
  );
}

/// Header seluruh halaman: Judul & subjudul memiliki lapisan perisai kontras adaptif
/// sehingga tidak pernah bertabrakan dengan awan, langit, maupun gedung di Light & Dark Mode.
class BandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double height;
  const BandHeader(this.title, {super.key, this.subtitle, this.trailing, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);

    // Badge capsule adaptif semi-transparan
    final badgeBg = dark
        ? Colors.black.withValues(alpha: 0.50)
        : Colors.black.withValues(alpha: 0.38);
    final badgeBorder = dark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.35);

    return CartoonHeader(
      height: height,
      bx: .82,
      bs: .48,
      groundY: .9,
      sunX: .55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Gradient Scrim lembut di bagian bawah agar teks selalu tajam
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    dark
                        ? Colors.black.withValues(alpha: 0.60)
                        : Colors.black.withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
          ),

          // 2. Konten Teks & Trailing
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: badgeBorder, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ],
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