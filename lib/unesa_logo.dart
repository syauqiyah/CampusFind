import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Memuat assets/unesa.png satu kali, lalu dipakai oleh semua painter logo.
class UnesaLogoCache {
  UnesaLogoCache._();

  static ui.Image? image;
  static Future<void>? _loading;

  /// Painter memakai ini sebagai `repaint` agar otomatis tergambar ulang
  /// begitu gambar selesai dimuat.
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static Future<void> ensureLoaded() {
    if (image != null) return Future<void>.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final data = await rootBundle.load('assets/unesa.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 180,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      notifier.value++;
    } catch (e) {
      debugPrint('Logo UNESA gagal dimuat: $e');
      _loading = null;
    }
  }
}

/// Menggambar logo UNESA (bagian yang berisi saja, tanpa margin kosong
/// pada gambar) pas di dalam [dst], proporsi tetap dan diletakkan di tengah.
void drawUnesaLogoFit(Canvas canvas, Rect dst) {
  final img = UnesaLogoCache.image;
  if (img == null) return;
  final iw = img.width.toDouble();
  final ih = img.height.toDouble();
  // Area berisi pada assets/unesa.png (gambar asli 225 x 192 px)
  final src = Rect.fromLTRB(iw * 26 / 225, ih * 7 / 192, iw * 199 / 225, ih);
  final scale = math.min(dst.width / src.width, dst.height / src.height);
  canvas.drawImageRect(
    img,
    src,
    Rect.fromCenter(
      center: dst.center,
      width: src.width * scale,
      height: src.height * scale,
    ),
    Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true,
  );
}

/// Menggambar lencana bulat biru tua berisi logo UNESA (emas) di [center].
/// Tidak menggambar apa pun jika gambar belum / gagal dimuat.
void drawUnesaBadge(Canvas canvas, Offset center, double radius) {
  final img = UnesaLogoCache.image;
  if (img == null) return;

  canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF0B357A));
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14,
  );

  final h = radius * 1.3;
  final w = h * img.width / img.height;
  canvas.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    Rect.fromCenter(center: center, width: w, height: h),
    Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true,
  );
}
