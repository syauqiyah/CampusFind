import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

Widget _buildUserAvatar(
    BuildContext context, {
      required double radius,
      String? overrideAvatarPath,
    }) {
  final photoUrl = store.currentUser?.photoUrl ?? '';
  final avatarImage =
  avatarProvider(overrideAvatarPath ?? settings.avatar);

  if (avatarImage != null) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: kDeep,
      backgroundImage: avatarImage,
    );
  }

  if (photoUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        photoUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: kDeep,
          child: Text(
            store.name.isNotEmpty ? store.name[0].toUpperCase() : 'U',
            style: TextStyle(
              fontSize: radius * 0.75,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: kDeep,
    child: Icon(
      Icons.person_rounded,
      size: radius * 1.1,
      color: Colors.white,
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _about(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
        TextButton(
            onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
      ],
    ),
  );

  void _logout(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Keluar akun?',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content:
      const Text('Kamu perlu login lagi untuk memakai CampusFind.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c), child: const Text('Batal')),
        TextButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            await store.logout();
            nav.pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const ChooseLoginScreen()),
                    (r) => false);
          },
          child: const Text('Keluar',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  Widget _menuItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        Color? color,
      }) {
    final dark = isDark(context);
    final textColor = color ?? (dark ? Colors.white : kSlateHeading);
    final iconColor =
        color ?? (dark ? const Color(0xFFCBD5E1) : kSlateSubLabel);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: mutedC(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([settings, store]),
    builder: (context, _) {
      final dark = isDark(context);
      final bgColor =
      dark ? const Color(0xFF09111E) : const Color(0xFFF1F5F9);
      final contactSubtitle = store.guard
          ? '${store.email} • ${store.guardPos}'
          : store.email;
      const double headerHeight = 165;

      return Container(
        color: bgColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              // 1. Latar Belakang Gedung Rektorat UNESA (Tetap ada seperti awal)
              BandHeader(
                'Profile',
                subtitle: store.guard
                    ? 'Satpam Pos UNESA • ${store.guardPos}'
                    : 'Mahasiswa UNESA',
                height: headerHeight,
              ),

              // 2. Konten Profil di atas Sheet Melengkung
              Container(
                margin: const EdgeInsets.only(top: headerHeight - 24),
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      (headerHeight - 24),
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  120 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Profil Atas (Statis / tidak bisa dipencet)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          _buildUserAvatar(context, radius: 34),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: dark
                                        ? Colors.white
                                        : kSlateHeading,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  contactSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mutedC(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Daftar Menu Utama
                    _menuItem(
                      context,
                      icon: Icons.person_outline_rounded,
                      label: 'My Profile',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const MyProfileDetailScreen()),
                      ),
                    ),
                    _menuItem(
                      context,
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const ProfileSettingsScreen()),
                      ),
                    ),
                    _menuItem(
                      context,
                      icon: Icons.menu_book_outlined,
                      label: 'Tutorial Penggunaan Aplikasi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const TutorialScreen(fromProfile: true)),
                      ),
                    ),
                    _menuItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: 'Tentang Aplikasi',
                      onTap: () => _about(context),
                    ),

                    const SizedBox(height: 10),
                    Divider(height: 1, color: borderC(context)),
                    const SizedBox(height: 10),

                    // Tombol Logout (Dinaikkan agar pas dan proporsional)
                    _menuItem(
                      context,
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      color: dark
                          ? const Color(0xFFF87171)
                          : const Color(0xFFDC2626),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------------------------ My Profile
class MyProfileDetailScreen extends StatefulWidget {
  const MyProfileDetailScreen({super.key});

  @override
  State<MyProfileDetailScreen> createState() => _MyProfileDetailScreenState();
}

class _MyProfileDetailScreenState extends State<MyProfileDetailScreen> {
  late final TextEditingController _nameCtrl;
  String _initialName = '';
  String? _initialAvatar;
  String? _draftAvatar;
  String _initialGender = '';
  String _selectedGender = '';
  bool _saving = false;

  String get _genderKey =>
      'user_gender_${store.guard ? "guard_" : ""}${store.email.toLowerCase()}';

  bool get _hasChanges =>
      _nameCtrl.text.trim() != _initialName ||
          _draftAvatar != _initialAvatar ||
          _selectedGender != _initialGender;

  @override
  void initState() {
    super.initState();
    _initialName = store.name;
    _nameCtrl = TextEditingController(text: _initialName)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _initialAvatar = settings.avatar;
    _draftAvatar = settings.avatar;
    _loadAccountGender();
  }

  Future<void> _loadAccountGender() async {
    final prefs = await SharedPreferences.getInstance();
    var g = prefs.getString(_genderKey) ?? '';

    if (g.isEmpty) {
      try {
        final db = FirebaseFirestore.instance;
        final uid = FirebaseAuth.instance.currentUser?.uid ??
            store.currentUser?.uid ??
            '';
        if (!store.guard && uid.isNotEmpty) {
          final doc = await db.collection('users').doc(uid).get();
          g = (doc.data()?['gender'] as String?) ?? '';
        } else if (store.guard && store.guardId.isNotEmpty) {
          final doc =
          await db.collection('satpam_officers').doc(store.guardId).get();
          g = (doc.data()?['gender'] as String?) ?? '';
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _initialGender = g;
      _selectedGender = g;
    });
  }

  Future<void> _saveChanges() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tampilan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (newName != _initialName) {
        await store.updateName(newName);
      }
      if (_draftAvatar != _initialAvatar && _draftAvatar != null) {
        await settings.setAvatar(_draftAvatar!);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_genderKey, _selectedGender);

      final db = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid ??
          store.currentUser?.uid ??
          '';
      if (!store.guard && uid.isNotEmpty) {
        await db.collection('users').doc(uid).set({
          'gender': _selectedGender,
          'email': store.email,
        }, SetOptions(merge: true));
      } else if (store.guard && store.guardId.isNotEmpty) {
        await db.collection('satpam_officers').doc(store.guardId).set({
          'gender': _selectedGender,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      setState(() {
        _initialName = newName;
        _initialAvatar = _draftAvatar;
        _initialGender = _selectedGender;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan profil berhasil disimpan!'),
          backgroundColor: kToska,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final toskaAccent = dark ? const Color(0xFF22B8CF) : kToska;

    return Scaffold(
      backgroundColor:
      dark ? const Color(0xFF09111E) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Foto Profil yang Bisa Diganti
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: toskaAccent.withValues(alpha: 0.45),
                      width: 2.2,
                    ),
                  ),
                  child: _buildUserAvatar(
                    context,
                    radius: 46,
                    overrideAvatarPath: _draftAvatar,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: TapScale(
                    onTap: () async {
                      final p = await pickImage(context);
                      if (p != null && mounted) {
                        setState(() => _draftAvatar = p);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kEmeraldSolid,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dark ? const Color(0xFF111D30) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Ketuk ikon kamera untuk mengganti foto profil',
              style: TextStyle(fontSize: 11.5, color: mutedC(context)),
            ),
          ),

          const SizedBox(height: 22),

          // Nama Tampilan (Bisa Diubah)
          AppField(
            'Nama Tampilan',
            'Masukkan nama lengkap',
            controller: _nameCtrl,
            icon: Icons.person_outline_rounded,
          ),

          // Jenis Kelamin (Gender sesuai akun login)
          const Text(
            'Jenis Kelamin (Gender)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedGender.isEmpty ? null : _selectedGender,
            hint: Text(
              'Pilih jenis kelamin',
              style: TextStyle(color: mutedC(context), fontSize: 13),
            ),
            items: const [
              DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
              DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedGender = v);
            },
            decoration: InputDecoration(
              prefixIcon:
              Icon(Icons.wc_rounded, size: 19, color: mutedC(context)),
              filled: true,
              fillColor: dark ? const Color(0xFF111D30) : Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderC(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderC(context)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact Detail (Email / ID Akun Login)
          const Text(
            'Contact Detail',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF111D30) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderC(context)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      store.guard
                          ? Icons.badge_outlined
                          : Icons.alternate_email_rounded,
                      size: 19,
                      color: toskaAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.guard
                                ? 'ID Petugas Login'
                                : 'Email Akun Login',
                            style:
                            TextStyle(fontSize: 11, color: mutedC(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store.email,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (store.guard) ...[
                  Divider(height: 20, color: borderC(context)),
                  Row(
                    children: [
                      Icon(Icons.local_police_outlined,
                          size: 19, color: toskaAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pos Penjagaan',
                              style: TextStyle(
                                  fontSize: 11, color: mutedC(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store.guardPos,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Tombol Save jika melakukan perubahan
          if (_hasChanges)
            PrimaryButton(
              _saving ? 'Menyimpan...' : 'Save',
              _saving ? null : _saveChanges,
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Settings
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) {
      final dark = isDark(context);

      return Scaffold(
        backgroundColor:
        dark ? const Color(0xFF09111E) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Settings', style: TextStyle(fontSize: 16)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF111D30) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderC(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text(
                      'Mode Gelap / Terang',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      settings.mode == ThemeMode.dark
                          ? 'Mode Gelap aktif'
                          : 'Mode Terang aktif',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: settings.mode == ThemeMode.dark,
                    activeThumbColor: kEmeraldSolid,
                    onChanged: settings.setDark,
                  ),
                  Divider(height: 1, color: borderC(context)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.text_fields_rounded),
                            SizedBox(width: 12),
                            Text(
                              'Ukuran Font',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<double>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                  value: 0.9, label: Text('Kecil')),
                              ButtonSegment(
                                  value: 1.0, label: Text('Sedang')),
                              ButtonSegment(
                                  value: 1.15, label: Text('Besar')),
                            ],
                            selected: {settings.fontScale},
                            onSelectionChanged: (s) =>
                                settings.setFont(s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}