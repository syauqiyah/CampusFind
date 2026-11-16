import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard.dart';
import 'cartoon.dart';
import 'core.dart';
import 'guard_screens.dart';
import 'splash_screen.dart';
import 'student_screens.dart';
import 'widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Widget? _resolvedNext;
  bool _alreadyLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialScreen();
  }

  Future<void> _resolveInitialScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getBool('guard_logged_in') == true) {
        store.guard = true;
        store.email = prefs.getString('guard_id') ?? 'Petugas Pos';
        store.guardPos = prefs.getString('guard_pos') ?? posList[0];
        await store.load();
        if (!mounted) return;
        setState(() {
          _resolvedNext = const GuardShell();
          _alreadyLoggedIn = true;
        });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final email = user.email!.toLowerCase();
        store.guard = false;
        store.email = email;
        await store.load();

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = (doc.data()?['role'] as String?) ?? 'student';

        if (!mounted) return;
        if (role == 'admin') {
          setState(() {
            _resolvedNext = AdminDashboardScreen(adminEmail: email);
            _alreadyLoggedIn = true;
          });
        } else {
          final seen = prefs.getBool('tutorial_seen') ?? false;
          setState(() {
            _resolvedNext = seen ? const StudentShell() : const TutorialScreen();
            _alreadyLoggedIn = true;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Auto-login check error: $e');
    }

    if (!mounted) return;
    setState(() {
      _resolvedNext = const ChooseLoginScreen();
      _alreadyLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CampusSplashScreen(
      nextScreen: _resolvedNext ?? const ChooseLoginScreen(),
      autoRedirect: _alreadyLoggedIn,
    );
  }
}
class AuthScaffold extends StatelessWidget {
  final String badgeText;
  final String title;
  final String subtitle;
  final double maxWidth;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    this.maxWidth = 480,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final subColor = dark ? Colors.white70 : const Color(0xFF475569);

    return Scaffold(
      body: Column(
        children: [
          CartoonHeader(
            height: 155,
            bx: .82,
            bs: .5,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (Navigator.canPop(context))
                      TapScale(
                        onTap: () => Navigator.pop(context),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: dark ? Colors.white24 : Colors.white.withValues(alpha: 0.94),
                            foregroundColor: dark ? Colors.white : kDeep,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: dark ? Colors.black45 : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: kGreen.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'UNESA LOST & FOUND PORTAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: dark ? Colors.white : kDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Brand Lockup Modern (Menggantikan teks hijau polos)
                      FadeSlideIn(
                        index: 0,
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutBack,
                              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      kGreen.withValues(alpha: 0.22),
                                      kDeep.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kGreen.withValues(alpha: 0.22),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const AppLogo(size: 62),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: kGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kGreen.withValues(alpha: 0.28)),
                              ),
                              child: Text(
                                badgeText.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: dark ? const Color(0xFF6EE7B7) : kDeep,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: dark
                                    ? const [Colors.white, Color(0xFFA7F3D0)]
                                    : const [kDeep, kGreen],
                              ).createShader(bounds),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: Text(
                                subtitle,
                                key: ValueKey(subtitle),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: subColor,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                          ],
                        ),
                      ),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChooseLoginScreen extends StatelessWidget {
  const ChooseLoginScreen({super.key});

  Widget _roleCard({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String roleTag,
    required String title,
    required String sub,
    required String btnLabel,
    required bool guard,
    required List<Color> iconGradient,
    required Color accent,
  }) {
    final dark = isDark(context);

    return FadeSlideIn(
      index: index,
      child: InteractiveCard(
        accentColor: accent,
        onTap: () => Navigator.push(context, smoothRoute(LoginScreen(guard: guard))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: iconGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 25),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleTag,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: TextStyle(
                fontSize: 13,
                color: mutedC(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              decoration: BoxDecoration(
                gradient: guard
                    ? null
                    : const LinearGradient(colors: [kDeep, kGreen]),
                color: guard ? accent.withValues(alpha: 0.10) : null,
                borderRadius: BorderRadius.circular(14),
                border: guard ? Border.all(color: accent.withValues(alpha: 0.45), width: 1.4) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    btnLabel,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: guard ? (dark ? Colors.white : accent) : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: guard ? (dark ? Colors.white : accent) : Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return AuthScaffold(
      badgeText: 'Pusat Barang Hilang & Temuan',
      title: 'Temukan Kembali\nBarang Berhargamu',
      subtitle: 'Sistem pelaporan terintegrasi & verifikasi pos satpam di lingkungan Universitas Negeri Surabaya.',
      maxWidth: isWide ? 840 : 480,
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _roleCard(
                  context: context,
                  index: 1,
                  icon: Icons.school_rounded,
                  roleTag: 'CIVITAS UNESA',
                  title: 'Login Warga UNESA',
                  sub: 'Mahasiswa, dosen, dan staf kampus dengan akun email resmi @unesa.ac.id untuk melapor & klaim barang.',
                  btnLabel: 'Masuk dengan Email UNESA',
                  guard: false,
                  iconGradient: const [kDeep, kGreen],
                  accent: kGreen,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _roleCard(
                  context: context,
                  index: 2,
                  icon: Icons.verified_user_rounded,
                  roleTag: 'PETUGAS POS',
                  title: 'Login Satpam Pos',
                  sub: 'Petugas keamanan gerbang kampus untuk validasi laporan fisik, QR Pos, dan serah terima barang.',
                  btnLabel: 'Masuk sebagai Satpam',
                  guard: true,
                  iconGradient: const [Color(0xFF0F766E), Color(0xFF0D9488)],
                  accent: const Color(0xFF0F766E),
                ),
              ),
            ],
          )
        else ...[
          _roleCard(
            context: context,
            index: 1,
            icon: Icons.school_rounded,
            roleTag: 'CIVITAS UNESA',
            title: 'Login Warga UNESA',
            sub: 'Mahasiswa, dosen, dan staf kampus dengan email UNESA untuk melapor & klaim barang.',
            btnLabel: 'Masuk dengan Email UNESA',
            guard: false,
            iconGradient: const [kDeep, kGreen],
            accent: kGreen,
          ),
          const SizedBox(height: 16),
          _roleCard(
            context: context,
            index: 2,
            icon: Icons.verified_user_rounded,
            roleTag: 'PETUGAS POS',
            title: 'Login Satpam Pos',
            sub: 'Petugas keamanan di pos gerbang kampus untuk verifikasi & serah terima barang.',
            btnLabel: 'Masuk sebagai Satpam',
            guard: true,
            iconGradient: const [Color(0xFF0F766E), Color(0xFF0D9488)],
            accent: const Color(0xFF0F766E),
          ),
        ],
      ],
    );
  }
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
  bool loading = false;
  bool isRegister = false;
  String? pos;

  static final _unesa = RegExp(r'^[\w.+\-]+@([\w\-]+\.)*unesa\.ac\.id$', caseSensitive: false);

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Login Satpam + simpan sesi lokal
      if (widget.guard) {
        final guardId = idC.text.trim();
        store.guard = true;
        store.email = guardId;
        store.guardPos = pos!;

        await prefs.setBool('guard_logged_in', true);
        await prefs.setString('guard_id', guardId);
        await prefs.setString('guard_pos', pos!);
        await store.load();

        final seen = prefs.getBool('guard_tutorial_seen') ?? false;
        if (!mounted) return;
        final Widget next = seen ? const GuardShell() : const TutorialScreen();
        Navigator.pushAndRemoveUntil(context, smoothRoute(next), (r) => false);
        return;
      }

      // 2. Login / Daftar Warga UNESA (Admin otomatis diarahkan jika role == 'admin')
      final email = idC.text.trim().toLowerCase();
      final password = passC.text;
      final auth = FirebaseAuth.instance;
      final db = FirebaseFirestore.instance;

      UserCredential cred;
      if (isRegister) {
        cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        cred = await auth.signInWithEmailAndPassword(email: email, password: password);
      }

      await prefs.remove('guard_logged_in');

      final uid = cred.user!.uid;
      final userRef = db.collection('users').doc(uid);
      final doc = await userRef.get();

      String role = 'student';
      if (!doc.exists) {
        final defaultName = email.split('@').first;
        await userRef.set({
          'email': email,
          'name': defaultName,
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        role = (doc.data()?['role'] as String?) ?? 'student';
      }

      store.guard = false;
      store.email = email;
      await store.load();

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          smoothRoute(AdminDashboardScreen(adminEmail: email)),
              (r) => false,
        );
        return;
      }

      final seen = prefs.getBool('tutorial_seen') ?? false;
      final Widget next = seen ? const StudentShell() : const TutorialScreen();
      Navigator.pushAndRemoveUntil(context, smoothRoute(next), (r) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Gagal masuk (${e.code})';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = 'Email atau password salah. Jika belum punya akun, klik Buat akun warga UNESA.';
      } else if (e.code == 'wrong-password') {
        msg = 'Password salah.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Email UNESA ini sudah terdaftar. Silakan Masuk.';
      } else if (e.code == 'weak-password') {
        msg = 'Password terlalu lemah (minimal 6 karakter).';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guard;
    return AuthScaffold(
      badgeText: g ? 'Akses Petugas Pos' : 'Autentikasi Civitas',
      title: g ? 'Portal Satpam Pos' : (isRegister ? 'Daftar Warga UNESA' : 'Masuk ke CampusFind'),
      subtitle: g
          ? 'Masukkan ID Petugas dan pilih lokasi pos penjagaan Anda.'
          : (isRegister
          ? 'Gunakan email institusi @unesa.ac.id untuk membuat akun baru.'
          : 'Gunakan email institusi @unesa.ac.id Anda untuk melanjutkan.'),
      maxWidth: 460,
      children: [
        FadeSlideIn(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardC(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderC(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark(context) ? 0.25 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppField(
                    g ? 'ID Petugas' : 'Email UNESA',
                    g ? 'Masukkan ID petugas' : 'nama@mhs.unesa.ac.id',
                    controller: idC,
                    icon: g ? Icons.badge_outlined : Icons.mail_outline_rounded,
                    keyboard: g ? TextInputType.text : TextInputType.emailAddress,
                    helper: g ? null : 'Hanya email berdomain UNESA (…@unesa.ac.id / …@mhs.unesa.ac.id)',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      if (!g && !_unesa.hasMatch(v.trim())) return 'Gunakan email UNESA (@unesa.ac.id)';
                      return null;
                    },
                  ),
                  const Text('Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: passC,
                    obscureText: hide,
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(hide ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: () => setState(() => hide = !hide),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (g)
                    AppDropdown(
                      'Bertugas di',
                      'Pilih pos satpam',
                      posList,
                      pos,
                          (v) => setState(() => pos = v),
                      isRequired: true,
                    ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: loading
                        ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: CircularProgressIndicator()),
                    )
                        : PrimaryButton(
                      key: ValueKey('btn_${g}_$isRegister'),
                      g ? 'Masuk ke Pos' : (isRegister ? 'Daftar & Masuk' : 'Masuk Sekarang'),
                      _login,
                    ),
                  ),
                  if (!g) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => isRegister = !isRegister),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isRegister
                                ? 'Sudah punya akun UNESA? Masuk di sini'
                                : 'Belum pernah mendaftar? Buat akun warga UNESA',
                            key: ValueKey(isRegister),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
    (Icons.mark_email_read_rounded, 'Masuk dengan Email UNESA', 'Login memakai email UNESA (@unesa.ac.id atau @mhs.unesa.ac.id) agar hanya warga kampus yang memakai aplikasi.'),
    (Icons.edit_note_rounded, 'Buat Laporan', 'Di menu Laporan pilih Lapor Kehilangan atau Lapor Barang Ditemukan. Isi data, foto, pos satpam (Gerbang Depan / Belakang), dan Detail Rahasia, yaitu ciri tersembunyi yang hanya kamu dan satpam tahu.'),
    (Icons.qr_code_2_rounded, 'Verifikasi QR Satpam', 'Tekan Lanjut untuk menampilkan QR. Datang ke pos dan minta satpam memindainya. QR selalu baru dan hanya berlaku 5 menit agar tidak bisa dipakai spam. Setelah disetujui, laporanmu tampil di Beranda.'),
    (Icons.auto_awesome_rounded, 'Notifikasi Pencocokan', 'Setelah laporan hilangmu disetujui, sistem mencocokkan otomatis dengan barang temuan. Notifikasi berbunyi dan menampilkan barang yang paling mirip beserta persentase kecocokan.'),
    (Icons.verified_rounded, 'Klaim Barang', 'Buka barang temuan di Beranda atau Cari, lalu Ajukan Klaim dan sebutkan detail rahasianya. Tunjukkan QR Klaim ke satpam. Jika cocok dan disetujui, barang diserahkan kepadamu.'),
  ];

  static const guardPages = [
    (Icons.dashboard_customize_rounded, 'Menu Beranda Satpam', 'Di menu Beranda, pantau antrean verifikasi laporan barang masuk dan daftar klaim warga yang menunggu tindakan di pos jaga Anda.'),
    (Icons.qr_code_scanner_rounded, 'QR Barcode Pos Satpam', 'Gunakan menu QR Pos untuk menampilkan kode QR dinamis pos jaga agar dipindai warga saat menyerahkan barang temuan atau mengambil barang klaim.'),
    (Icons.fact_check_rounded, 'Verifikasi Detail Rahasia', 'Saat meninjau klaim, aplikasi menampilkan kotak perbandingan antara detail rahasia pelapor dengan jawaban pengklaim secara berdampingan.'),
    (Icons.task_alt_rounded, 'Keputusan & Serah Terima', 'Tekan tombol hijau "Setujui Klaim & Serahkan Barang" jika data cocok, atau tombol bergaris "Tolak Klaim" jika data tidak sesuai.'),
    (Icons.filter_list_rounded, 'Filter di Menu Laporan', 'Buka menu Laporan untuk melihat seluruh arsip. Gunakan chip filter status dan filter pos di bagian atas untuk menyortir data.'),
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
    Navigator.pushAndRemoveUntil(context, smoothRoute(destination), (r) => false);
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              Expanded(
                child: PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  controller: pc,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => page = i),
                  itemBuilder: (_, i) => AnimatedBuilder(
                    animation: pc,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (pc.position.haveDimensions) {
                        final diff = ((pc.page ?? page.toDouble()) - i).abs();
                        scale = (1 - (diff * 0.14)).clamp(0.86, 1.0);
                      }
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: kGreen.withValues(alpha: 0.08)),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: kGreen.withValues(alpha: 0.16),
                            child: Icon(pages[i].$1, size: 54, color: kGreen),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(pages[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(pages[i].$3, textAlign: TextAlign.center, style: TextStyle(color: mutedC(context), height: 1.55, fontSize: 13.5)),
                      ]),
                    ),
                  ),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.all(4),
                    width: i == page ? 26 : 8,
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
                    pc.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutQuart);
                  }
                }),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}