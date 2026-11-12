import 'dart:io';
import 'package:flutter/material.dart';
import 'auth_screens.dart';
import 'cartoon.dart';
import 'core.dart';
import 'widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _section(BuildContext c, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mutedC(c))),
  );

  Widget _box(BuildContext c, List<Widget> children) => Container(
    decoration: BoxDecoration(color: cardC(c), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(c))),
    child: Column(children: children),
  );

  void _about(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Column(children: [AppLogo(size: 72), SizedBox(height: 10), Text('CampusFind', style: TextStyle(fontWeight: FontWeight.bold))]),
      content: const Text(
        'CampusFind membantu warga UNESA melaporkan, mencari, dan mengklaim barang hilang atau ditemukan di lingkungan kampus, dengan verifikasi satpam di pos gerbang depan dan belakang.\n\nVersi 2.0.0',
        textAlign: TextAlign.center,
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))],
    ),
  );

  void _logout(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Keluar akun?'),
      content: const Text('Kamu perlu login lagi untuk memakai CampusFind.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
        TextButton(
          onPressed: () {
            store.logout();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ChooseLoginScreen()), (r) => false);
          },
          child: const Text('Keluar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => ListView(padding: const EdgeInsets.only(bottom: 96), children: [
      BandHeader(
        'Profil Saya',
        subtitle: store.guard ? 'Petugas Satpam • ${store.guardPos}' : 'Civitas Academica UNESA',
        height: 165,
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Stack(children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: kDeep,
                backgroundImage: settings.avatar != null && File(settings.avatar!).existsSync() ? FileImage(File(settings.avatar!)) : null,
                child: settings.avatar == null ? const Icon(Icons.person, size: 52, color: Colors.white) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: () async {
                    final p = await pickImage(context);
                    if (p != null) settings.setAvatar(p);
                  },
                  child: const CircleAvatar(radius: 15, backgroundColor: kGreen, child: Icon(Icons.camera_alt, size: 15, color: Colors.white)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Center(child: Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Center(child: Text(store.guard ? 'Petugas Satpam • ${store.guardPos}' : store.email, style: TextStyle(fontSize: 12, color: mutedC(context)))),
          _section(context, 'SETELAN'),
          _box(context, [
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Mode Gelap', style: TextStyle(fontSize: 14)),
              subtitle: Text(settings.mode == ThemeMode.dark ? 'Gelap' : 'Terang', style: const TextStyle(fontSize: 12)),
              value: settings.mode == ThemeMode.dark,
              activeThumbColor: kGreen,
              onChanged: settings.setDark,
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.text_fields), SizedBox(width: 12), Text('Ukuran Font', style: TextStyle(fontSize: 14))]),
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
              title: const Text('Tutorial Penggunaan', style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen(fromProfile: true))),
            ),
          ]),
          _section(context, 'LAINNYA'),
          _box(context, [
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('Tentang Aplikasi', style: TextStyle(fontSize: 14)), trailing: const Icon(Icons.chevron_right), onTap: () => _about(context)),
          ]),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size.fromHeight(48)),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar Akun'),
          ),
        ]),
      ),
    ]),
  );
}