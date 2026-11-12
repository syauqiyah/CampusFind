import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'core.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 90});
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: Transform.scale(scale: 1.12, child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const PrimaryButton(this.label, this.onTap, {super.key, this.outlined = false});
  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final text = Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600));
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: kGreen, side: const BorderSide(color: kGreen), shape: shape), onPressed: onTap, child: text)
          : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white, elevation: 0, shape: shape), onPressed: onTap, child: text),
    );
  }
}

InputDecoration _deco(BuildContext c, String hint, {IconData? icon, String? helper}) => InputDecoration(
  hintText: hint,
  helperText: helper,
  helperMaxLines: 3,
  hintStyle: const TextStyle(fontSize: 13),
  prefixIcon: icon == null ? null : Icon(icon, size: 18),
  filled: true,
  fillColor: cardC(c),
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(c))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(c))),
);

Widget _label(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
);

String? requiredField(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

class AppField extends StatelessWidget {
  final String label, hint;
  final TextEditingController? controller;
  final bool obscure, readOnly;
  final int maxLines;
  final IconData? icon;
  final String? helper;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final VoidCallback? onTap;
  const AppField(this.label, this.hint, {super.key, this.controller, this.obscure = false, this.readOnly = false, this.maxLines = 1, this.icon, this.helper, this.validator, this.keyboard, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboard,
        onTap: onTap,
        validator: validator,
        decoration: _deco(context, hint, icon: icon, helper: helper),
      ),
    ]),
  );
}

class AppDropdown extends StatelessWidget {
  final String label, hint;
  final String? value, helper;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  const AppDropdown(this.label, this.hint, this.items, this.value, this.onChanged, {super.key, this.isRequired = false, this.helper});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: Text(hint, style: const TextStyle(fontSize: 13)),
        decoration: _deco(context, hint, helper: helper).copyWith(hintText: null),
        validator: isRequired ? (v) => v == null ? 'Wajib dipilih' : null : null,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    ]),
  );
}

class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = {
      'Hilang': Colors.red,
      'Ditemukan': kGreen,
      stWait: Colors.orange,
      stActive: kGreen,
      stClaimed: Colors.amber.shade800,
      stDone: Colors.blueGrey,
      stRejected: Colors.red,
      'Menunggu': Colors.orange,
      'Disetujui': kGreen,
      'Ditolak': Colors.red,
    }[label] ??
        Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class TagBadge extends StatelessWidget {
  final String text;
  final Color color;
  const TagBadge(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

/// Foto laporan; jika tidak ada foto, tampil placeholder kartun berwarna sesuai kategori.
class ReportPhoto extends StatelessWidget {
  final Report r;
  const ReportPhoto(this.r, {super.key});

  Widget _ph() {
    final i = categories.indexOf(r.category);
    const pal = [Color(0xFF2E9E6B), Color(0xFF3B8EDC), Color(0xFFE4893A), Color(0xFF8A6FD1), Color(0xFFD9627A), Color(0xFF2BA4A0), Color(0xFF7A9A2E), Color(0xFF607D8B)];
    final col = pal[i < 0 ? 0 : i];
    return LayoutBuilder(
      builder: (c, k) => Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [col.withValues(alpha: .7), col])),
        child: Center(child: Icon(r.icon, size: (k.biggest.shortestSide.isFinite ? k.biggest.shortestSide : 80) * .42, color: Colors.white.withValues(alpha: .95))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = r.photo;
    if (p != null && File(p).existsSync()) {
      return Image.file(File(p), fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => _ph());
    }
    return _ph();
  }
}

/// Kartu barang ala marketplace: foto di atas, keterangan di bawah, bisa diketuk.
class ItemCard extends StatelessWidget {
  final Report r;
  final VoidCallback onTap;
  const ItemCard(this.r, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(fit: StackFit.expand, children: [
            ReportPhoto(r),
            Positioned(left: 8, top: 8, child: TagBadge(r.typeLabel, r.type == ReportType.hilang ? Colors.red : kGreen)),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text(r.categoryLabel, style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
            if (r.status == stClaimed)
              Positioned(
                right: 0,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.amber.shade800, borderRadius: const BorderRadius.horizontal(left: Radius.circular(8))),
                  child: const Text('Diklaim', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.place_outlined, size: 12, color: mutedC(context)),
                  const SizedBox(width: 2),
                  Expanded(child: Text(r.area, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: mutedC(context)))),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.local_police_outlined, size: 12, color: mutedC(context)),
                  const SizedBox(width: 2),
                  Expanded(child: Text('${r.pos.replaceFirst('Pos ', '')}\n${fmtDate(r.date)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: mutedC(context)))),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    ),
  );
}

class ReportTile extends StatelessWidget {
  final Report r;
  final VoidCallback onTap;
  const ReportTile(this.r, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC(context))),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 56, height: 56, child: ReportPhoto(r))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${r.id}\n${fmtDate(r.date)}', style: TextStyle(fontSize: 11, color: mutedC(context))),
              Text(r.pos, style: TextStyle(fontSize: 11, color: mutedC(context))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusChip(r.typeLabel),
            const SizedBox(height: 4),
            StatusChip(r.status),
          ]),
        ]),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC(context))),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 56, height: 56, child: r == null ? const SizedBox() : ReportPhoto(r))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Klaim: ${r?.name ?? c.reportId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${c.id}\n${c.claimer}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: mutedC(context))),
              ]),
            ),
            StatusChip(c.status),
          ]),
        ),
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const FilterChips(this.options, this.selected, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final o in options)
        ChoiceChip(
          label: Text(o, style: TextStyle(fontSize: 12, color: o == selected ? Colors.white : null)),
          selected: o == selected,
          selectedColor: kGreen,
          showCheckmark: false,
          onSelected: (_) => onChanged(o),
        ),
    ],
  );
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const InfoRow(this.icon, this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: kGreen),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: mutedC(context))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    ]),
  );
}

class SecretBox extends StatelessWidget {
  final String title, text;
  final Color color;
  const SecretBox(this.title, this.text, {super.key, this.color = kGreen});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.lock, size: 15, color: color), const SizedBox(width: 6), Expanded(child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)))]),
      const SizedBox(height: 6),
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    ]),
  );
}

Future<String?> pickImage(BuildContext context) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Ambil foto (kamera)'), onTap: () => Navigator.pop(c, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Pilih dari galeri'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
      ]),
    ),
  );
  if (src == null) return null;
  final x = await ImagePicker().pickImage(source: src, imageQuality: 80, maxWidth: 1600);
  return x?.path;
}

class PhotoBox extends StatelessWidget {
  final String? path;
  final ValueChanged<String> onPicked;
  const PhotoBox({super.key, required this.path, required this.onPicked});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final p = await pickImage(context);
      if (p != null) onPicked(p);
    },
    child: Container(
      height: 160,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC(context))),
      child: path == null
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_a_photo_outlined, color: kGreen, size: 32),
        const SizedBox(height: 6),
        Text('Ketuk untuk upload foto barang', style: TextStyle(fontSize: 12, color: mutedC(context))),
      ])
          : Stack(fit: StackFit.expand, children: [
        Image.file(File(path!), fit: BoxFit.cover),
        const Positioned(right: 8, bottom: 8, child: CircleAvatar(radius: 14, backgroundColor: kGreen, child: Icon(Icons.edit, size: 14, color: Colors.white))),
      ]),
    ),
  );
}

class NavItem {
  final IconData icon, selIcon;
  final String label;
  final int badge;
  const NavItem(this.icon, this.selIcon, this.label, {this.badge = 0});
}

/// Bar navigasi melayang berbentuk kapsul
class FloatingNav extends StatelessWidget {
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  const FloatingNav({super.key, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 6, 14, bottomInset > 0 ? bottomInset + 4 : 14),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: cardC(context),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: borderC(context)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .14), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(34),
                  onTap: () => onTap(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: i == index ? (isDark(context) ? kGreen.withValues(alpha: .25) : kLeaf) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Badge(
                        isLabelVisible: items[i].badge > 0,
                        label: Text('${items[i].badge}'),
                        child: Icon(i == index ? items[i].selIcon : items[i].icon, size: 24, color: i == index ? kGreen : mutedC(context)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(items[i].label, style: TextStyle(fontSize: 10, fontWeight: i == index ? FontWeight.w700 : FontWeight.w500, color: i == index ? kGreen : mutedC(context))),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}