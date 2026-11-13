import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cartoon.dart';
import 'core.dart';
import 'guard_screens.dart';
import 'student_screens.dart';
import 'widgets.dart';
import 'splash_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const CampusSplashScreen(
      nextScreen: ChooseLoginScreen(),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  final String subtitle;
  final List<Widget> children;
  const AuthScaffold({super.key, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final brandColor = dark ? Colors.white : const Color(0xFF1E824C);
    final subColor = dark ? Colors.white70 : Colors.black54;

    return Scaffold(
      body: Column(
        children: [
          // 1. Header Ilustrasi Kampus Murni (tanpa container logo mengambang)
          CartoonHeader(
            height: 170,
            bx: .82,
            bs: .5,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Navigator.canPop(context))
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: dark ? Colors.white24 : Colors.white.withOpacity(0.9),
                          foregroundColor: dark ? Colors.white : const Color(0xFF1E824C),
                        ),
                      )
                    else
                      const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),

          // 2. Body Form & Logo/Judul Terpusat di Bawah Gambar Ilustrasi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                // Logo & Judul "CampusFind" di Tengah (Center Alignment)
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const AppLogo(size: 64),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'CampusFind',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: brandColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Form Children (Input Email, Password, Tombol Masuk, dll)
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChooseLoginScreen extends StatelessWidget {
  const ChooseLoginScreen({super.key});
  Widget _card(BuildContext c, IconData icon, String title, String sub, String btn, bool guard) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(color: cardC(c), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC(c))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: kGreen), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
      const SizedBox(height: 4),
      Text(sub, style: TextStyle(fontSize: 12, color: mutedC(c))),
      const SizedBox(height: 12),
      PrimaryButton(btn, () => Navigator.push(c, MaterialPageRoute(builder: (_) => LoginScreen(guard: guard))), outlined: guard),
    ]),
  );

  @override
  Widget build(BuildContext context) => AuthScaffold(subtitle: 'Selamat datang!', children: [
    const Text('Pilih jenis login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14),
    _card(context, Icons.groups, 'Login Warga UNESA', 'Mahasiswa, dosen, dan tenaga kependidikan dengan email UNESA', 'Masuk sebagai Warga UNESA', false),
    _card(context, Icons.verified_user, 'Login Satpam', 'Untuk petugas keamanan di pos gerbang kampus', 'Masuk sebagai Satpam', true),
  ]);
}

class LoginScreen extends StatefulWidget {
  final bool guard;
  const LoginScreen({super.key, required this.guard});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final idC = TextEditingController();
  final passC = TextEditingController();
  bool hide = true;
  String? pos;

  static final _unesa = RegExp(r'^[\w.+\-]+@([\w\-]+\.)*unesa\.ac\.id$', caseSensitive: false);

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    store.guard = widget.guard;
    store.email = widget.guard ? idC.text.trim() : idC.text.trim().toLowerCase();
    if (widget.guard) store.guardPos = pos!;

    final prefs = await SharedPreferences.getInstance();
    final key = widget.guard ? 'guard_tutorial_seen' : 'tutorial_seen';
    final seen = prefs.getBool(key) ?? false;

    if (!mounted) return;
    final Widget next = seen
        ? (widget.guard ? const GuardShell() : const StudentShell())
        : const TutorialScreen();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => next), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guard;
    return AuthScaffold(
      subtitle: g ? 'Login Satpam' : 'Login Warga UNESA',
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppField(
              g ? 'ID Petugas' : 'Email UNESA',
              g ? 'Masukkan ID petugas' : 'nama@mhs.unesa.ac.id',
              controller: idC,
              icon: g ? Icons.badge_outlined : Icons.mail_outline,
              keyboard: g ? TextInputType.text : TextInputType.emailAddress,
              helper: g ? null : 'Hanya email berdomain UNESA (…@unesa.ac.id / …@mhs.unesa.ac.id)',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (!g && !_unesa.hasMatch(v.trim())) return 'Gunakan email UNESA (@unesa.ac.id)';
                return null;
              },
            ),
            const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: passC,
              obscureText: hide,
              validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
              decoration: InputDecoration(
                hintText: 'Masukkan password',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => hide = !hide)),
                filled: true,
                fillColor: cardC(context),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
              ),
            ),
            const SizedBox(height: 14),
            if (g) AppDropdown('Bertugas di', 'Pilih pos satpam', posList, pos, (v) => setState(() => pos = v), isRequired: true),
            const SizedBox(height: 8),
            PrimaryButton('Masuk', _login),
          ]),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- tutorial
class TutorialScreen extends StatefulWidget {
  final bool fromProfile;
  const TutorialScreen({super.key, this.fromProfile = false});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final pc = PageController();
  int page = 0;

  static const studentPages = [
    (Icons.mark_email_read, 'Masuk dengan Email UNESA', 'Login memakai email UNESA (@unesa.ac.id atau @mhs.unesa.ac.id) agar hanya warga kampus yang memakai aplikasi.'),
    (Icons.edit_note, 'Buat Laporan', 'Di menu Laporan pilih Lapor Kehilangan atau Lapor Barang Ditemukan. Isi data, foto, pos satpam (Gerbang Depan / Belakang), dan Detail Rahasia, yaitu ciri tersembunyi yang hanya kamu dan satpam tahu.'),
    (Icons.qr_code_2, 'Verifikasi QR Satpam', 'Tekan Lanjut untuk menampilkan QR. Datang ke pos dan minta satpam memindainya. QR selalu baru dan hanya berlaku 2 menit agar tidak bisa dipakai spam. Setelah disetujui, laporanmu tampil di Beranda.'),
    (Icons.auto_awesome, 'Notifikasi Pencocokan', 'Setelah laporan hilangmu disetujui, sistem mencocokkan otomatis dengan barang temuan. Notifikasi berbunyi dan menampilkan barang yang paling mirip beserta persentase kecocokan.'),
    (Icons.verified, 'Klaim Barang', 'Buka barang temuan di Beranda atau Cari, lalu Ajukan Klaim dan sebutkan detail rahasianya. Tunjukkan QR Klaim ke satpam. Jika cocok dan disetujui, barang diserahkan kepadamu.'),
  ];

  static const guardPages = [
    (Icons.dashboard_customize, 'Menu Beranda Satpam', 'Di menu Beranda, pantau antrean verifikasi laporan barang masuk dan daftar klaim warga yang menunggu tindakan di pos jaga Anda.'),
    (Icons.qr_code_scanner, 'Scan QR Laporan & Klaim', 'Gunakan menu Scan QR untuk memindai kode QR dari layar HP warga saat mereka menyerahkan barang temuan atau saat mengambil barang yang diklaim.'),
    (Icons.fact_check, 'Verifikasi Detail Rahasia', 'Saat meninjau klaim, aplikasi menampilkan kotak perbandingan antara detail rahasia pelapor dengan jawaban pengklaim secara berdampingan.'),
    (Icons.task_alt, 'Keputusan & Serah Terima', 'Tekan tombol hijau "Setujui Klaim & Serahkan Barang" jika data cocok, atau tombol bergaris "Tolak Klaim" jika data tidak sesuai.'),
    (Icons.filter_list, 'Filter di Menu Laporan', 'Buka menu Laporan untuk melihat seluruh arsip. Gunakan chip filter status dan filter pos di bagian atas untuk menyortir data.'),
  ];

  Future<void> _finish() async {
    if (widget.fromProfile) {
      Navigator.pop(context);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = store.guard ? 'guard_tutorial_seen' : 'tutorial_seen';
    await prefs.setBool(key, true);
    if (!mounted) return;
    final Widget destination = store.guard ? const GuardShell() : const StudentShell();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => destination), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = store.guard ? guardPages : studentPages;
    final last = page == pages.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(store.guard ? 'Tutorial Aplikasi Satpam' : 'Tutorial Penggunaan', style: const TextStyle(fontSize: 16)),
        actions: [if (!last) TextButton(onPressed: _finish, child: const Text('Lewati'))],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: pc,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircleAvatar(radius: 56, backgroundColor: kGreen.withOpacity(.15), child: Icon(pages[i].$1, size: 56, color: kGreen)),
                  const SizedBox(height: 28),
                  Text(pages[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(pages[i].$3, textAlign: TextAlign.center, style: TextStyle(color: mutedC(context), height: 1.5)),
                ]),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(color: i == page ? kGreen : borderC(context), borderRadius: BorderRadius.circular(8)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: PrimaryButton(last ? (widget.fromProfile ? 'Selesai' : 'Mulai Gunakan') : 'Lanjut', () {
              if (last) {
                _finish();
              } else {
                pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
              }
            }),
          ),
        ]),
      ),
    );
  }
}