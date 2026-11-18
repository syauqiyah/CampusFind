import 'dart:io';
import 'package:flutter/material.dart';
import 'auth_screens.dart';
import 'cartoon.dart';
import 'core.dart';
import 'widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _section(BuildContext c, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Text(
      t,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: mutedC(c)),
    ),
  );

  Widget _box(BuildContext c, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: cardC(c),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderC(c)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark(c) ? 0.22 : 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      type: MaterialType.transparency,
      child: Column(children: children),
    ),
  );

  void _editName(BuildContext context) {
    final ctrl = TextEditingController(text: store.name);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Ubah Nama Tampilan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Masukkan nama lengkap',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                await store.updateName(val);
              }
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _about(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Column(children: [
        AppLogo(size: 72),
        SizedBox(height: 10),
        Text('CampusFind', style: TextStyle(fontWeight: FontWeight.w800)),
      ]),
      content: const Text(
        'CampusFind membantu warga UNESA melaporkan, mencari, dan mengklaim barang hilang atau ditemukan di lingkungan kampus, dengan verifikasi satpam di pos gerbang depan dan belakang.\n\nVersi 2.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.45),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
      ],
    ),
  );

  void _logout(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Keluar akun?', style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('Kamu perlu login lagi untuk memakai CampusFind.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
        TextButton(
          onPressed: () {
            store.logout();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ChooseLoginScreen()), (r) => false);
          },
          child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([settings, store]),
    builder: (context, _) => ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 120 + MediaQuery.viewPaddingOf(context).bottom),
      children: [
        BandHeader(
          'Profil Saya',
          subtitle: store.guard ? 'Petugas Satpam • ${store.guardPos}' : 'Civitas Academica UNESA',
          height: 165,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FadeSlideIn(
              index: 0,
              child: Column(children: [
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Stack(children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kGreen.withValues(alpha: 0.35), width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: kDeep,
                          backgroundImage: settings.avatar != null && File(settings.avatar!).existsSync()
                              ? FileImage(File(settings.avatar!))
                              : null,
                          child: settings.avatar == null ? const Icon(Icons.person_rounded, size: 52, color: Colors.white) : null,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: TapScale(
                          onTap: () async {
                            final p = await pickImage(context);
                            if (p != null) settings.setAvatar(p);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: kGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardC(context), width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TapScale(
                    onTap: () => _editName(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, size: 17, color: kGreen),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    store.guard ? 'Petugas Satpam • ${store.guardPos}' : store.email,
                    style: TextStyle(fontSize: 12, color: mutedC(context)),
                  ),
                ),
              ]),
            ),
            FadeSlideIn(
              index: 1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _section(context, 'SETELAN'),
                _box(context, [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Nama Tampilan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(store.name, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.edit_outlined, size: 18, color: kGreen),
                    onTap: () => _editName(context),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Mode Gelap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(settings.mode == ThemeMode.dark ? 'Gelap' : 'Terang', style: const TextStyle(fontSize: 12)),
                    value: settings.mode == ThemeMode.dark,
                    activeThumbColor: kGreen,
                    onChanged: settings.setDark,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.text_fields_rounded),
                        SizedBox(width: 12),
                        Text('Ukuran Font', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<double>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 0.9, label: Text('Kecil')),
                            ButtonSegment(value: 1.0, label: Text('Sedang')),
                            ButtonSegment(value: 1.15, label: Text('Besar')),
                          ],
                          selected: {settings.fontScale},
                          onSelectionChanged: (s) => settings.setFont(s.first),
                        ),
                      ),
                    ]),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('Tutorial Penggunaan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen(fromProfile: true))),
                  ),
                ]),
              ]),
            ),
            FadeSlideIn(
              index: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _section(context, 'LAINNYA'),
                _box(context, [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Tentang Aplikasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _about(context),
                  ),
                ]),
                const SizedBox(height: 20),
                TapScale(
                  onTap: () => _logout(context),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ],
    ),
  );
}