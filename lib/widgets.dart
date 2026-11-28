import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'cartoon.dart';
import 'core.dart';
import 'unesa_logo.dart';

const List<Color> cardColors = [
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFD84315),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFFEF6C00),
];

const Color kEmeraldSolid = kToska;        // #1080A6 (Toska Utama)
const Color kForestSolid = kNavyPrimary;   // #0B2058 (Biru Utama UNESA)
const Color kSlateHeading = Color(0xFF0F172A);
const Color kSlateSubLabel = Color(0xFF334155);

// Palet Dark Mode Navy & Toska (serasi dengan core.dart & main.dart)
const Color _kDarkCard = Color(0xFF111D30);
const Color _kDarkBorder = Color(0xFF1E3250);
const Color _kDarkToska = Color(0xFF22B8CF);
const Color _kLightBorder = Color(0xFFDCE6F2);

Widget sectionHeading(BuildContext context, String title, {String? trailing}) {
  final dark = isDark(context);
  return Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: dark ? _kDarkToska : kEmeraldSolid,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : kSlateHeading,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: dark ? const Color(0xFFCBD5E1) : kSlateSubLabel,
          ),
        ),
    ],
  );
}

BoxDecoration emeraldGlassDecoration(
    BuildContext context, {
      double radius = 18,
      Color? accentBorder,
      double borderWidth = 1.1,
      bool elevated = true,
    }) {
  final dark = isDark(context);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: dark ? _kDarkCard : Colors.white,
    border: Border.all(
      width: borderWidth,
      color: accentBorder ?? (dark ? _kDarkBorder : _kLightBorder),
    ),
    boxShadow: elevated
        ? [
      BoxShadow(
        color: (dark ? Colors.black : kDeep)
            .withValues(alpha: dark ? 0.24 : 0.045),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ]
        : null,
  );
}

class EmeraldGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final bool elevated;

  const EmeraldGlass({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.padding,
    this.margin,
    this.blur = 0,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: emeraldGlassDecoration(
        context,
        radius: borderRadius,
        elevated: elevated,
      ),
      child: child,
    );
  }
}

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  const TapScale(
      {super.key, required this.child, this.onTap, this.scaleDown = 0.965});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
      widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = curve;
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(curve);

    final delay = Duration(milliseconds: (widget.index.clamp(0, 6)) * 35);
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String suffix;
  const AnimatedCounter(this.value, {super.key, this.style, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  final double width, height, radius;
  const ShimmerBox(
      {super.key,
        this.width = double.infinity,
        required this.height,
        this.radius = 12});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final base = dark ? const Color(0xFF15243B) : const Color(0xFFE6EEF6);
    final highlight = dark ? const Color(0xFF213757) : const Color(0xFFF5F9FD);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3.0, -0.2),
            end: Alignment(-0.5 + _ctrl.value * 3.0, 0.2),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}

class ShimmerTileList extends StatelessWidget {
  final int count;
  const ShimmerTileList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      count,
          (_) => EmeraldGlass(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        borderRadius: 18,
        elevated: false,
        child: const Row(
          children: [
            ShimmerBox(width: 56, height: 56, radius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 14, radius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ShimmerCardGrid extends StatelessWidget {
  final int count;
  const ShimmerCardGrid({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: count,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.80,
    ),
    itemBuilder: (_, __) => EmeraldGlass(
      borderRadius: 18,
      elevated: false,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ShimmerBox(height: double.infinity, radius: 0)),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 110, height: 13, radius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 80, height: 10, radius: 6),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

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
        color: dark ? const Color(0xFF0F172A) : Colors.white,
        border: Border.all(
          color: dark
              ? const Color(0xFF93C5FD).withValues(alpha: 0.45)
              : _kLightBorder,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : kDeep).withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
  _CampusFindLogoPainter() : super(repaint: UnesaLogoCache.notifier);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    canvas.save();
    canvas.scale(s, s);

    canvas.drawCircle(
        const Offset(60, 60), 60, Paint()..color = const Color(0xFF093275));

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
    canvas.drawCircle(const Offset(23, 65.5), 2.6,
        Paint()..color = const Color(0xFFFBBF24));

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

    final sparkPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(35, 15), const Offset(39, 12), sparkPaint);
    canvas.drawLine(const Offset(37, 20), const Offset(42, 19), sparkPaint);
    canvas.drawLine(const Offset(90, 16), const Offset(94, 14), sparkPaint);
    canvas.drawLine(const Offset(91, 21), const Offset(95, 21), sparkPaint);

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

    canvas.drawCircle(const Offset(60, 61), 27, Paint()..color = Colors.white);
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
    canvas.drawPath(
      Path()
        ..moveTo(43, 50)
        ..lineTo(60, 39)
        ..lineTo(77, 50)
        ..lineTo(60, 54)
        ..close(),
      Paint()..color = const Color(0xFFC2410C),
    );
    final facadeBlue = Paint()..color = const Color(0xFF1D74E8);
    canvas.drawRect(const Rect.fromLTWH(46.5, 55, 9, 28), facadeBlue);
    canvas.drawRect(const Rect.fromLTWH(64.5, 55, 9, 28), facadeBlue);
    canvas.drawRect(const Rect.fromLTWH(58.5, 54, 3, 29),
        Paint()..color = const Color(0xFFE2E8F0));

    if (UnesaLogoCache.image == null) {
      canvas.drawRect(const Rect.fromLTWH(56, 54, 8, 8),
          Paint()..color = const Color(0xFF1E3A8A));
    }
    drawUnesaBadge(canvas, const Offset(60, 59.5), 7.4);

    canvas.restore();

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

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  const PrimaryButton(this.label, this.onPressed,
      {super.key, this.outlined = false});
  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final accent = dark ? _kDarkToska : kEmeraldSolid;
    return TapScale(
      onTap: onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: outlined
            ? OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: accent, width: 1.4),
            foregroundColor: accent,
            backgroundColor: accent.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onPressed,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null
                ? Colors.grey.shade400
                : kEmeraldSolid,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onPressed,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

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
  const AppField(
      this.label,
      this.hint, {
        super.key,
        required this.controller,
        this.icon,
        this.suffix,
        this.obscure = false,
        this.readOnly = false,
        this.maxLines = 1,
        this.helper,
        this.validator,
        this.onTap,
        this.keyboard,
        this.keyboardType,
      });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 19, color: mutedC(context)),
            suffixIcon: suffix,
            filled: true,
            fillColor: dark ? _kDarkCard : Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: dark ? _kDarkBorder : _kLightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: dark ? _kDarkBorder : _kLightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: dark ? _kDarkToska : kEmeraldSolid, width: 1.6),
            ),
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(helper!,
                style: TextStyle(
                    fontSize: 11, color: mutedC(context), height: 1.35)),
          ),
      ]),
    );
  }
}

class AppDropdown extends StatelessWidget {
  final String label, hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final String? helper;
  const AppDropdown(
      this.label, this.hint, this.items, this.value, this.onChanged,
      {super.key, this.isRequired = false, this.helper});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(color: mutedC(context), fontSize: 13)),
          items: items
              .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
          validator:
          isRequired ? (v) => v == null ? 'Wajib dipilih' : null : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: dark ? _kDarkCard : Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: dark ? _kDarkBorder : _kLightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: dark ? _kDarkBorder : _kLightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: dark ? _kDarkToska : kEmeraldSolid, width: 1.6),
            ),
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(helper!,
                style: TextStyle(
                    fontSize: 11, color: mutedC(context), height: 1.35)),
          ),
      ]),
    );
  }
}

Future<String?> pickImage(BuildContext context,
    {bool hasCurrent = false}) async {
  final choice = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari Galeri'),
            onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil Foto dari Kamera'),
            onTap: () => Navigator.pop(c, ImageSource.camera)),
        if (hasCurrent)
          ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
              const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(c)),
      ]),
    ),
  );
  if (choice == null) return null;
  final x = await ImagePicker().pickImage(
      source: choice, maxWidth: 640, maxHeight: 640, imageQuality: 70);
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

/// Gambar dengan memory cache agar scroll katalog cepat dan bebas lag.
class PhotoImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const PhotoImage(this.path, {super.key, this.fit = BoxFit.cover});

  static final Map<String, Uint8List> _memCache = {};

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('data:image')) {
      try {
        if (_memCache.length > 80) {
          _memCache.remove(_memCache.keys.first);
        }
        final bytes = _memCache.putIfAbsent(
          path,
              () => base64Decode(path.split(',').last),
        );
        return Image.memory(
          bytes,
          fit: fit,
          cacheWidth: 420,
          gaplessPlayback: true,
        );
      } catch (_) {}
    }
    if (!kIsWeb && File(path).existsSync()) {
      return Image.file(File(path), fit: fit, cacheWidth: 420);
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
  Widget build(BuildContext context) => TapScale(
    onTap: () => _pick(context),
    child: EmeraldGlass(
      borderRadius: 18,
      elevated: false,
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: path != null
            ? Stack(fit: StackFit.expand, children: [
          PhotoImage(path!),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Ganti',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11))
                  ]),
            ),
          ),
        ])
            : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  size: 30,
                  color: isDark(context)
                      ? _kDarkToska
                      : kEmeraldSolid),
              const SizedBox(height: 6),
              Text('Tambah Foto',
                  style: TextStyle(
                      color: mutedC(context), fontSize: 13)),
            ]),
      ),
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
      child: Center(
          child: Icon(catIcons[r.category] ?? Icons.inventory_2_outlined,
              size: iconSize, color: Colors.white)),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  const StatusChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final c = switch (text) {
      'Ditemukan' || stActive || 'Disetujui' => kEmeraldSolid,
      'Hilang' || stRejected || 'Ditolak' => Colors.red.shade600,
      stWait || 'Menunggu' => Colors.amber.shade800,
      _ => kSlateSubLabel,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: dark ? c.withValues(alpha: 0.24) : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? Colors.white : c,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  const FilterChips(this.items, this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((s) {
          final on = value == s;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(s,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? Colors.white : null)),
              selected: on,
              selectedColor: kEmeraldSolid,
              backgroundColor: dark ? _kDarkCard : Colors.white,
              side: BorderSide(
                  color: on
                      ? kEmeraldSolid
                      : (dark ? _kDarkBorder : _kLightBorder)),
              showCheckmark: false,
              onSelected: (_) => onChanged(s),
            ),
          );
        }).toList(),
      ),
    );
  }
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
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: mutedC(context))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
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
      decoration: BoxDecoration(
          color: c.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: 0.6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock, size: 15, color: c),
          const SizedBox(width: 6),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: c))),
        ]),
        const SizedBox(height: 6),
        Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Report r;
  final VoidCallback onTap;
  const ItemCard(this.r, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return TapScale(
      onTap: onTap,
      child: EmeraldGlass(
        borderRadius: 18,
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(17)),
              child: Stack(fit: StackFit.expand, children: [
                ReportPhoto(r, iconSize: 40),
                Positioned(top: 8, left: 8, child: StatusChip(r.typeLabel)),
                if (r.status == stDone)
                  Positioned(top: 8, right: 8, child: StatusChip(r.status)),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(r.categoryLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.local_police_outlined,
                        size: 12,
                        color: dark ? _kDarkToska : kEmeraldSolid),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(r.pos,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: mutedC(context)))),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: mutedC(context)),
                    const SizedBox(width: 3),
                    Text(fmtDate(r.date),
                        style:
                        TextStyle(fontSize: 10, color: mutedC(context))),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

class ReportTile extends StatelessWidget {
  final Report r;
  final VoidCallback onTap;
  const ReportTile(this.r, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) {
    final locText = (r.area.trim().isEmpty || r.area.trim() == r.pos.trim())
        ? r.pos
        : '${r.area} • ${r.pos}';
    return TapScale(
      onTap: onTap,
      child: EmeraldGlass(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        borderRadius: 18,
        child: Row(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                  width: 58,
                  height: 58,
                  child: ReportPhoto(r, iconSize: 28))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(locText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: mutedC(context))),
                  const SizedBox(height: 6),
                  Wrap(
                      spacing: 6,
                      children: [StatusChip(r.typeLabel), StatusChip(r.status)]),
                ]),
          ),
          Icon(Icons.chevron_right_rounded, color: mutedC(context)),
        ]),
      ),
    );
  }
}

class ClaimTile extends StatelessWidget {
  final Claim c;
  final VoidCallback onTap;
  const ClaimTile(this.c, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) {
    final r = store.find(c.reportId);
    final accent = isDark(context) ? _kDarkToska : kEmeraldSolid;
    return TapScale(
      onTap: onTap,
      child: EmeraldGlass(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        borderRadius: 18,
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.how_to_reg_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r?.name ?? 'Barang',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text('Pengklaim: ${c.claimer}',
                  style: TextStyle(fontSize: 11, color: mutedC(context))),
              const SizedBox(height: 6),
              StatusChip(c.status),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: mutedC(context)),
        ]),
      ),
    );
  }
}

class QrBox extends StatelessWidget {
  final String data;
  const QrBox(this.data, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kLightBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: QrImageView(data: data, size: 220, backgroundColor: Colors.white),
  );
}

class NavItem {
  final IconData icon, activeIcon;
  final String label;
  final int badge;
  const NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});
}

/// Navbar dengan cekungan gelombang & tombol melingkar menonjol yang bergeser mulus
/// mengikuti semua tab yang aktif tanpa terpotong di tab pertama/terakhir.
class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final int? centerIndex;
  final String? centerTooltip;

  const FloatingNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.items,
    this.centerIndex,
    this.centerTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final int count = items.length;
    if (count == 0) return const SizedBox.shrink();

    final int activeIdx = index.clamp(0, count - 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 0, 12, (bottomInset > 0 ? bottomInset : 10) + 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalW = constraints.maxWidth;
          const double sidePad = 18.0;
          final double usableW = totalW - sidePad * 2;
          final double slotW = usableW / count;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: activeIdx.toDouble()),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, animIndex, _) {
              final double notchCenterX =
                  sidePad + slotW * (animIndex + 0.5);
              final NavItem activeItem = items[activeIdx];

              return SizedBox(
                height: 92,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Bilah latar navigasi dengan cekungan gelombang bergerak
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 66,
                      child: CustomPaint(
                        painter: _SlidingWaveBarPainter(
                          notchCenterX: notchCenterX,
                          dark: dark,
                        ),
                      ),
                    ),

                    // 2. Deretan slot tab
                    Positioned(
                      left: sidePad,
                      right: sidePad,
                      bottom: 0,
                      height: 66,
                      child: Row(
                        children: [
                          for (int i = 0; i < count; i++)
                            Expanded(
                              child: _buildFlatTabItem(
                                i,
                                items[i],
                                isSelected: i == activeIdx,
                                dark: dark,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 3. Tombol bulat toska melayang yang presisi tepat di atas cekungan
                    Positioned(
                      left: notchCenterX - 25,
                      bottom: 25,
                      child: GestureDetector(
                        onTap: () => onTap(activeIdx),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kEmeraldSolid,
                                border: Border.all(
                                  color: dark ? _kDarkCard : Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kEmeraldSolid.withValues(alpha: 0.36),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  activeItem.activeIcon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            if (activeItem.badge > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE11D48),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: dark ? _kDarkCard : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${activeItem.badge}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFlatTabItem(
      int i,
      NavItem it, {
        required bool isSelected,
        required bool dark,
      }) {
    final activeColor = dark ? _kDarkToska : kEmeraldSolid;
    final inactiveColor = dark ? Colors.white60 : const Color(0xFF64748B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isSelected)
            Badge(
              isLabelVisible: it.badge > 0,
              backgroundColor: const Color(0xFFE11D48),
              label: Text(
                '${it.badge}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
              child: Icon(
                it.icon,
                size: 22,
                color: inactiveColor,
              ),
            )
          else
            const SizedBox(height: 22),
          const SizedBox(height: 4),
          Text(
            it.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Path _buildSlidingWaveNotchPath(Size size, double cx) {
  const double r = 22.0;
  final double w = size.width;
  final double h = size.height;
  final double clampedCx = cx.clamp(r + 36.0, w - r - 36.0);

  return Path()
    ..moveTo(r, 0)
    ..lineTo(clampedCx - 42, 0)
    ..cubicTo(clampedCx - 26, 0, clampedCx - 25, 29, clampedCx, 29)
    ..cubicTo(clampedCx + 25, 29, clampedCx + 26, 0, clampedCx + 42, 0)
    ..lineTo(w - r, 0)
    ..quadraticBezierTo(w, 0, w, r)
    ..lineTo(w, h - r)
    ..quadraticBezierTo(w, h, w - r, h)
    ..lineTo(r, h)
    ..quadraticBezierTo(0, h, 0, h - r)
    ..lineTo(0, r)
    ..quadraticBezierTo(0, 0, r, 0)
    ..close();
}

class _SlidingWaveBarPainter extends CustomPainter {
  final double notchCenterX;
  final bool dark;

  const _SlidingWaveBarPainter({
    required this.notchCenterX,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildSlidingWaveNotchPath(size, notchCenterX);

    final shadowPaint = Paint()
      ..color = (dark ? Colors.black : kDeep).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = dark ? _kDarkCard : Colors.white;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = dark ? _kDarkBorder : _kLightBorder;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SlidingWaveBarPainter oldDelegate) =>
      oldDelegate.notchCenterX != notchCenterX || oldDelegate.dark != dark;
}

PageRouteBuilder<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accentColor;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.accentColor,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? kEmeraldSolid;
    final scale = _pressed ? 0.975 : (_hovered ? 1.015 : 1.0);
    final translateY = _hovered && !_pressed ? -4.0 : 0.0;

    return MouseRegion(
      cursor:
      widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, translateY)
            ..scale(scale, scale),
          transformAlignment: Alignment.center,
          padding: widget.padding,
          decoration: emeraldGlassDecoration(
            context,
            radius: widget.radius,
            accentBorder: _hovered ? accent.withValues(alpha: 0.75) : null,
            borderWidth: _hovered ? 1.5 : 1.1,
            elevated: true,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// -------------------------------------------------- shared home sections
class HomeHeader extends StatelessWidget {
  final String name;
  final String? subtitle;
  final VoidCallback? onProfile;
  final double height;

  const HomeHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.onProfile,
    this.height = 285,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final photoUrl = store.currentUser?.photoUrl ?? '';
    final infoText = (subtitle != null && subtitle!.isNotEmpty)
        ? 'Halo, $name • $subtitle'
        : 'Halo, $name';

    return CartoonHeader(
      height: height,
      bx: .5,
      bs: .52,
      groundY: .80,
      sunX: .82,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogo(size: 46),
                const SizedBox(width: 10),
                Expanded(
                  child: TapScale(
                    onTap: onProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.84)
                            : Colors.white.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: dark ? _kDarkBorder : _kLightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: dark ? 0.28 : 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Campus',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        height: 1.0,
                                        color:
                                        dark ? Colors.white : kSlateHeading,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6.5, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: kEmeraldSolid,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Find',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          height: 1.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  infoText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (photoUrl.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ClipOval(
                              child: Image.network(
                                photoUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => CircleAvatar(
                                  radius: 16,
                                  backgroundColor: kSlateSubLabel,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (onProfile != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: mutedC(context)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner ringkas status & jam operasional pos satpam (untuk Beranda Mahasiswa).
class HomePosStatusPill extends StatelessWidget {
  final VoidCallback? onTap;
  const HomePosStatusPill({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final now = DateTime.now();
    final isOpen =
        now.weekday != DateTime.sunday && now.hour >= 7 && now.hour < 21;
    final totalPos = store.availablePosList.length;

    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? _kDarkCard : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? _kDarkBorder : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? (dark ? _kDarkToska : kEmeraldSolid) : Colors.orange.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOpen
                    ? '$totalPos Pos Satpam Aktif • 07.00 – 21.00 WIB'
                    : '$totalPos Pos Satpam • Layanan 07.00 – 21.00 WIB',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dark ? const Color(0xFFE2E8F0) : kForestSolid,
                ),
              ),
            ),
            Text(
              'Info Pos',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: dark ? const Color(0xFF38BDF8) : kEmeraldSolid,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: dark ? const Color(0xFF38BDF8) : kEmeraldSolid,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeHoursCard extends StatelessWidget {
  const HomeHoursCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final now = DateTime.now();
    final isOpen =
        now.weekday != DateTime.sunday && now.hour >= 7 && now.hour < 21;
    final accent = dark ? _kDarkToska : kEmeraldSolid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? _kDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? _kDarkBorder : _kLightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.access_time_filled_rounded,
                color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Jam Operasional Pos Satpam',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isOpen ? accent : Colors.orange)
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOpen ? 'Buka' : 'Tutup',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOpen
                              ? (dark ? const Color(0xFF38BDF8) : kEmeraldSolid)
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '07.00 – 21.00 WIB',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : kSlateHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Senin – Sabtu • ${store.availablePosList.length} Pos Layanan Kampus',
                  style: TextStyle(fontSize: 11.5, color: mutedC(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeNewsSection extends StatelessWidget {
  const HomeNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final pub = store.reports.where((r) => r.isPublic).toList();
    final foundCount = pub.where((r) => r.type == ReportType.ditemukan).length;
    final lostCount = pub.where((r) => r.type == ReportType.hilang).length;

    final items = [
      (
      icon: Icons.inventory_2_outlined,
      accent: dark ? _kDarkToska : kEmeraldSolid,
      tag: 'Temuan',
      title: '$foundCount Barang Temuan Siap Diklaim',
      date:
      'Tersimpan di ${store.availablePosList.length} titik pos satpam kampus',
      ),
      (
      icon: Icons.search_rounded,
      accent: kSlateSubLabel,
      tag: 'Kehilangan',
      title: '$lostCount Laporan Kehilangan Aktif',
      date: 'Dicocokkan otomatis oleh sistem CampusFind',
      ),
      (
      icon: Icons.qr_code_scanner_rounded,
      accent: Colors.amber.shade800,
      tag: 'Informasi',
      title: 'Panduan Verifikasi & Klaim di Pos',
      date: 'Scan QR Pos Satpam saat menyerahkan atau mengambil barang',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeading(context, 'Berita Terkini'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: dark ? _kDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark ? _kDarkBorder : _kLightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.18 : 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 68,
                    endIndent: 14,
                    color: dark
                        ? _kDarkBorder.withValues(alpha: 0.8)
                        : const Color(0xFFE2E8F0),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: items[i].accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(items[i].icon,
                            color: dark && items[i].accent == kSlateSubLabel
                                ? const Color(0xFFCBD5E1)
                                : items[i].accent,
                            size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].tag.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: dark && items[i].accent == kSlateSubLabel
                                    ? const Color(0xFF94A3B8)
                                    : items[i].accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : kSlateHeading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].date,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: mutedC(context),
                                  height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}