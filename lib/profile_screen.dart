import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'auth_screens.dart';
import 'cartoon.dart';
import 'core.dart';
import 'widgets.dart';

String? _avatarCacheKey;
ImageProvider? _avatarCacheValue;

ImageProvider? avatarProvider(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw == _avatarCacheKey) return _avatarCacheValue;
  ImageProvider? provider;
  try {
    if (raw.startsWith('data:image')) {
      provider = MemoryImage(base64Decode(raw.split(',').last));
    } else if (!kIsWeb && File(raw).existsSync()) {
      provider = FileImage(File(raw));
    }
  } catch (_) {
    provider = null;
  }
  _avatarCacheKey = raw;
  _avatarCacheValue = provider;
  return provider;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _section(BuildContext c, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
    child: sectionHeading(c, t),
  );

  Widget _box(BuildContext c, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: isDark(c) ? const Color(0xFF13291F) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark(c) ? const Color(0xFF2E5A44) : const Color(0xFFD1E7DD),
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark(c) ? Colors.black : kDeep).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              backgroundColor: kEmeraldSolid,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Column(children: [
        AppLogo(size: 72),
        SizedBox(height: 10),
        Text('CampusFind', style: TextStyle(fontWeight: FontWeight.w800)),
      ]),
      content: const Text(
        'CampusFind membantu mahasiswa UNESA melaporkan, mencari, dan mengklaim barang hilang atau ditemukan di kampus dengan verifikasi satpam di pos gerbang depan dan belakang.\n\nVersi 2.0.0',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Keluar akun?', style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('Kamu perlu login lagi untuk memakai CampusFind.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
        TextButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            await store.logout();
            nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const ChooseLoginScreen()), (r) => false);
          },
          child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([settings, store]),
    builder: (context, _) {
      final dark = isDark(context);
      final neutralIconColor = dark ? const Color(0xFFCBD5E1) : kSlateSubLabel;

      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 120 + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          BandHeader(
            'Profil Saya',
            subtitle: store.guard ? 'Satpam Pos UNESA • ${store.guardPos}' : 'Mahasiswa UNESA',
            height: 165,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              FadeSlideIn(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF13291F) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dark ? const Color(0xFF2E5A44) : const Color(0xFFD1E7DD),
                    ),
                  ),
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
                              border: Border.all(color: neutralIconColor.withValues(alpha: 0.4), width: 2.2),
                            ),
                            child: Builder(builder: (_) {
                              final photoUrl = store.currentUser?.photoUrl ?? '';
                              final avatarImage = avatarProvider(settings.avatar);

                              if (avatarImage != null) {
                                return CircleAvatar(
                                  radius: 44,
                                  backgroundColor: kDeep,
                                  backgroundImage: avatarImage,
                                );
                              }

                              if (photoUrl.isNotEmpty) {
                                return ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => CircleAvatar(
                                      radius: 44,
                                      backgroundColor: kDeep,
                                      child: Text(
                                        store.name.isNotEmpty ? store.name[0].toUpperCase() : 'M',
                                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return const CircleAvatar(
                                radius: 44,
                                backgroundColor: kDeep,
                                child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
                              );
                            }),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: TapScale(
                              onTap: () async {
                                final p = await pickImage(context);
                                if (p != null) settings.setAvatar(p);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: kEmeraldSolid,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: dark ? const Color(0xFF13291F) : Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
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
                              Icon(Icons.edit_rounded, size: 17, color: neutralIconColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        store.guard ? 'Satpam Pos UNESA • ${store.guardPos}' : store.email,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: dark ? const Color(0xFFE2E8F0) : kSlateSubLabel,
                        ),
                      ),
                    ),
                  ]),
                ),
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
                      trailing: Icon(Icons.edit_outlined, size: 18, color: neutralIconColor),
                      onTap: () => _editName(context),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Mode Gelap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(settings.mode == ThemeMode.dark ? 'Gelap' : 'Terang', style: const TextStyle(fontSize: 12)),
                      value: settings.mode == ThemeMode.dark,
                      activeThumbColor: kEmeraldSolid,
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
      );
    },
  );
}