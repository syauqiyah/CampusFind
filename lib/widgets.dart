import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'core.dart';

const List<Color> cardColors = [
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFD84315),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFFEF6C00),
];

// ------------------------------------------------------------------ logo aplikasi
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.065),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
            const Color(0xFF1E3A6E).withValues(alpha: 0.92),
            const Color(0xFF0F172A).withValues(alpha: 0.95),
          ]
              : [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFE0F2FE).withValues(alpha: 0.90),
          ],
        ),
        border: Border.all(
          color: dark
              ? const Color(0xFF93C5FD).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.92),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? const Color(0xFF38BDF8).withValues(alpha: 0.28)
                : const Color(0xFF0B357A).withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          if (dark)
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
              blurRadius: 14,
            ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _CampusFindLogoPainter(),
        ),
      ),
    );
  }
}

class _CampusFindLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    canvas.save();
    canvas.scale(s, s);

    // 1. Latar lingkaran biru navy UNESA (#093275)
    canvas.drawCircle(
        const Offset(60, 60), 60, Paint()..color = const Color(0xFF093275));

    // 2. Garis orbit biru muda & putih
    final skyArc = Paint()
      ..color = const Color(0xFF67C3F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: const Offset(60, 60), radius: 43),
        -1.95, 0.76, false, skyArc);
    canvas.drawArc(Rect.fromCircle(center: const Offset(60, 60), radius: 42),
        2.55, 0.42, false, skyArc);
    canvas.drawArc(Rect.fromCircle(center: const Offset(60, 60), radius: 42),
        -0.34, 0.46, false, skyArc);

    final whiteArc = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: const Offset(60, 60), radius: 43),
        0.95, 1.25, false, whiteArc);

    // 3. Ikon Kiri Atas: Dompet Biru & Emas
    canvas.drawCircle(const Offset(34, 30), 15, Paint()..color = Colors.white);
    canvas.drawPath(
      Path()
        ..moveTo(27, 27)
        ..lineTo(40, 24)
        ..lineTo(41, 29)
        ..lineTo(27, 30)
        ..close(),
      Paint()..color = const Color(0xFFFBBF24),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(26, 27, 16, 10), const Radius.circular(2.5)),
      Paint()..color = const Color(0xFF1D4ED8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(37, 30, 6, 4), const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF1E3A8A),
    );
    canvas.drawCircle(
        const Offset(39.5, 32), 1.2, Paint()..color = Colors.white);

    // 4. Ikon Kiri Bawah: Tumbler Biru & Lambang Emas
    canvas.drawCircle(
        const Offset(23, 64), 13.5, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(20, 55, 6, 3), const Radius.circular(1)),
      Paint()..color = const Color(0xFF1E3A8A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(18.5, 58, 9, 15), const Radius.circular(2.5)),
      Paint()..color = const Color(0xFF1D4ED8),
    );
    canvas.drawCircle(
        const Offset(23, 65.5), 2.6, Paint()..color = const Color(0xFFFBBF24));

    // 5. Ikon Kanan Atas: Jam Tangan Biru & Emas
    canvas.drawCircle(const Offset(88, 30), 15, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(85, 19, 6, 22), const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF1D4ED8),
    );
    canvas.drawCircle(
        const Offset(88, 30), 6.5, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawCircle(
        const Offset(88, 30), 4.8, Paint()..color = const Color(0xFF1E3A8A));
    canvas.drawPath(
      Path()
        ..moveTo(88, 27.5)
        ..lineTo(88, 30)
        ..lineTo(90, 31.2),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // 6. Ikon Kanan Bawah: Kunci & Gantungan Biru
    canvas.drawCircle(const Offset(95, 71), 14, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(92, 68), 3.5, Paint()..color = const Color(0xFFCBD5E1));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(90.8, 71, 2.4, 8), const Radius.circular(1)),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    canvas.save();
    canvas.translate(96, 68);
    canvas.rotate(-0.26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 6, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFF1D4ED8),
    );
    canvas.restore();

    // Percikan bintang emas kecil di sekitar ikon
    final sparkPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(35, 15), const Offset(39, 12), sparkPaint);
    canvas.drawLine(const Offset(37, 20), const Offset(42, 19), sparkPaint);
    canvas.drawLine(const Offset(90, 16), const Offset(94, 14), sparkPaint);
    canvas.drawLine(const Offset(91, 21), const Offset(95, 21), sparkPaint);

    // 7. Gagang Kaca Pembesar
    canvas.save();
    canvas.translate(78, 78);
    canvas.rotate(pi / 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, -4, 26, 9), const Radius.circular(4.5)),
      Paint()..color = const Color(0xFF1D4ED8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, -2.5, 18, 3), const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF67C3F3),
    );
    canvas.restore();

    // 8. Lensa Kaca Pembesar Tengah (Gedung Rektorat & Lambang UNESA)
    canvas.drawCircle(
        const Offset(60, 61), 27, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: const Offset(60, 61), radius: 24.5)));

    canvas.drawRect(const Rect.fromLTWH(34, 35, 52, 52),
        Paint()..color = const Color(0xFF38BDF8));
    canvas.drawCircle(
        const Offset(40, 70), 9, Paint()..color = const Color(0xFF16A34A));
    canvas.drawCircle(
        const Offset(80, 70), 9, Paint()..color = const Color(0xFF16A34A));
    canvas.drawCircle(
        const Offset(48, 73), 7, Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(
        const Offset(72, 73), 7, Paint()..color = const Color(0xFF22C55E));

    // Gedung melengkung putih di dalam lensa
    canvas.drawPath(
      Path()
        ..moveTo(44, 50)
        ..lineTo(60, 44)
        ..lineTo(76, 50)
        ..lineTo(76, 84)
        ..lineTo(44, 84)
        ..close(),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    // Atap limasan terakota
    canvas.drawPath(
      Path()
        ..moveTo(43, 50)
        ..lineTo(60, 39)
        ..lineTo(77, 50)
        ..lineTo(60, 54)
        ..close(),
      Paint()..color = const Color(0xFFC2410C),
    );
    // Sayap kaca biru kiri
    canvas.drawRect(const Rect.fromLTWH(47, 53, 11, 29),
        Paint()..color = const Color(0xFF0284C7));
    // Lencana logo emas UNESA di dalam lensa
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(49, 54, 7, 9), const Radius.circular(1)),
      Paint()..color = const Color(0xFF1E3A8A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(52.5, 55.2)
        ..lineTo(53.2, 60.5)
        ..lineTo(51.8, 60.5)
        ..close(),
      Paint()..color = const Color(0xFFFBBF24),
    );
    // Garis biru horizontal sayap kanan
    final blueBand = Paint()..color = const Color(0xFF1D4ED8);
    for (final by in [56.0, 61.0, 66.0, 71.0]) {
      canvas.drawRect(Rect.fromLTWH(60, by, 15, 2.4), blueBand);
    }

    canvas.restore();

    // Bingkai putih lensa
    canvas.drawCircle(
      const Offset(60, 61),
      25.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------------ tombol utama
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  const PrimaryButton(this.label, this.onPressed, {super.key, this.outlined = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: outlined
        ? OutlinedButton(
      style: OutlinedButton.styleFrom(side: const BorderSide(color: kGreen), foregroundColor: kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    )
        : ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ),
  );
}

// ------------------------------------------------------------------ input field
class AppField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData? icon;
  final Widget? suffix;
  final bool obscure, readOnly;
  final int maxLines;
  final String? helper;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final TextInputType? keyboard;
  final TextInputType? keyboardType;
  const AppField(this.label, this.hint, {super.key, required this.controller, this.icon, this.suffix, this.obscure = false, this.readOnly = false, this.maxLines = 1, this.helper, this.validator, this.onTap, this.keyboard, this.keyboardType});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        keyboardType: keyboard ?? keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: mutedC(context), fontSize: 13),
          prefixIcon: icon == null ? null : Icon(icon, size: 19, color: mutedC(context)),
          suffixIcon: suffix,
          filled: true,
          fillColor: cardC(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 1.5)),
        ),
      ),
      if (helper != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(helper!, style: TextStyle(fontSize: 11, color: mutedC(context), height: 1.35)),
        ),
    ]),
  );
}

class AppDropdown extends StatelessWidget {
  final String label, hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final String? helper;
  const AppDropdown(this.label, this.hint, this.items, this.value, this.onChanged, {super.key, this.isRequired = false, this.helper});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        hint: Text(hint, style: TextStyle(color: mutedC(context), fontSize: 13)),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
        validator: isRequired ? (v) => v == null ? 'Wajib dipilih' : null : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: cardC(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
        ),
      ),
      if (helper != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(helper!, style: TextStyle(fontSize: 11, color: mutedC(context), height: 1.35)),
        ),
    ]),
  );
}

// ------------------------------------------------------------------ foto
Future<String?> pickImage(BuildContext context, {bool hasCurrent = false}) async {
  final choice = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Pilih dari Galeri'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Ambil Foto dari Kamera'), onTap: () => Navigator.pop(c, ImageSource.camera)),
        if (hasCurrent) ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(c)),
      ]),
    ),
  );
  if (choice == null) return null;
  final x = await ImagePicker().pickImage(source: choice, maxWidth: 640, maxHeight: 640, imageQuality: 70);
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

class PhotoImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const PhotoImage(this.path, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('data:image')) {
      try {
        final raw = path.split(',').last;
        return Image.memory(base64Decode(raw), fit: fit, gaplessPlayback: true);
      } catch (_) {}
    }
    if (!kIsWeb && File(path).existsSync()) {
      return Image.file(File(path), fit: fit);
    }
    return const SizedBox();
  }
}

class PhotoBox extends StatelessWidget {
  final String? path;
  final ValueChanged<String?> onPicked;
  const PhotoBox({super.key, required this.path, required this.onPicked});

  Future<void> _pick(BuildContext context) async {
    final res = await pickImage(context, hasCurrent: path != null);
    onPicked(res);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _pick(context),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
      clipBehavior: Clip.antiAlias,
      child: path != null
          ? Stack(fit: StackFit.expand, children: [
        PhotoImage(path!),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit, size: 14, color: Colors.white), SizedBox(width: 4), Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 11))]),
          ),
        ),
      ])
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_a_photo_outlined, size: 30, color: kGreen),
        const SizedBox(height: 6),
        Text('Tambah Foto', style: TextStyle(color: mutedC(context), fontSize: 13)),
      ]),
    ),
  );
}

class ReportPhoto extends StatelessWidget {
  final Report r;
  final double iconSize;
  const ReportPhoto(this.r, {super.key, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    if (r.photo != null) {
      return PhotoImage(r.photo!);
    }
    final idx = r.id.hashCode.abs() % cardColors.length;
    return Container(
      color: cardColors[idx],
      child: Center(child: Icon(catIcons[r.category] ?? Icons.inventory_2_outlined, size: iconSize, color: Colors.white)),
    );
  }
}

// ------------------------------------------------------------------ chip & baris info
class StatusChip extends StatelessWidget {
  final String text;
  const StatusChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = switch (text) {
      'Ditemukan' || stActive || 'Disetujui' => kGreen,
      'Hilang' || stRejected || 'Ditolak' => Colors.red.shade600,
      stWait || 'Menunggu' => Colors.orange.shade700,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  const FilterChips(this.items, this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: items.map((s) {
        final on = value == s;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(s, style: TextStyle(fontSize: 12, color: on ? Colors.white : null)),
            selected: on,
            selectedColor: kGreen,
            backgroundColor: cardC(context),
            side: BorderSide(color: on ? kGreen : borderC(context)),
            showCheckmark: false,
            onSelected: (_) => onChanged(s),
          ),
        );
      }).toList(),
    ),
  );
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const InfoRow(this.icon, this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: mutedC(context)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: mutedC(context))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ),
    ]),
  );
}

class SecretBox extends StatelessWidget {
  final String title, text;
  final Color? color;
  const SecretBox(this.title, this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.amber.shade800;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(12), border: Border.all(color: c)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock, size: 15, color: c),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c))),
        ]),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ------------------------------------------------------------------ kartu barang (grid)
class ItemCard extends StatelessWidget {
  final Report r;
  final VoidCallback onTap;
  const ItemCard(this.r, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC(context))),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            ReportPhoto(r, iconSize: 40),
            Positioned(top: 8, left: 8, child: StatusChip(r.typeLabel)),
            if (r.status == stDone) Positioned(top: 8, right: 8, child: StatusChip(r.status)),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(r.categoryLabel, style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.place_outlined, size: 12, color: mutedC(context)),
              const SizedBox(width: 2),
              Expanded(child: Text(r.area, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: mutedC(context)))),
            ]),
            const SizedBox(height: 1),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 11, color: mutedC(context)),
              const SizedBox(width: 3),
              Text(fmtDate(r.date), style: TextStyle(fontSize: 10, color: mutedC(context))),
            ]),
          ]),
        ),
      ]),
    ),
  );
}

// ------------------------------------------------------------------ tile laporan & klaim
class ReportTile extends StatelessWidget {
  final Report r;
  final VoidCallback onTap;
  const ReportTile(this.r, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 58, height: 58, child: ReportPhoto(r, iconSize: 28))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text('${r.area} • ${r.pos}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: mutedC(context))),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [StatusChip(r.typeLabel), StatusChip(r.status)]),
          ]),
        ),
        Icon(Icons.chevron_right, color: mutedC(context)),
      ]),
    ),
  );
}

class ClaimTile extends StatelessWidget {
  final Claim c;
  final VoidCallback onTap;
  const ClaimTile(this.c, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) {
    final r = store.find(c.reportId);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
        child: Row(children: [
          CircleAvatar(backgroundColor: softC(context), child: const Icon(Icons.how_to_reg, color: kGreen)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r?.name ?? 'Barang', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('Pengklaim: ${c.claimer}', style: TextStyle(fontSize: 11, color: mutedC(context))),
              const SizedBox(height: 6),
              StatusChip(c.status),
            ]),
          ),
          Icon(Icons.chevron_right, color: mutedC(context)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ QR & navigasi mengambang
class QrBox extends StatelessWidget {
  final String data;
  const QrBox(this.data, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: QrImageView(data: data, size: 220, backgroundColor: Colors.white),
  );
}

class NavItem {
  final IconData icon, activeIcon;
  final String label;
  final int badge;
  const NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});
}

class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  const FloatingNav({super.key, required this.index, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: cardC(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderC(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark(context) ? .45 : .14), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final it = items[i];
          final on = i == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: on ? kGreen.withValues(alpha: .16) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                    child: Badge(
                      isLabelVisible: it.badge > 0,
                      label: Text('${it.badge}'),
                      child: Icon(on ? it.activeIcon : it.icon, size: 22, color: on ? kGreen : mutedC(context)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? kGreen : mutedC(context))),
                ]),
              ),
            ),
          );
        }),
      ),
    ),
  );
}