import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard.dart';
import 'cartoon.dart';
import 'core.dart';
import 'guard_screens.dart';
import 'splash_screen.dart';
import 'student_screens.dart';
import 'widgets.dart';

const Color _kSlateTitle = Color(0xFF0F172A);
const Color _kToskaMain = kToska; // #1080A6
const Color _kNavyUnesa = kNavyPrimary; // #0B2058

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

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        try {
          user = await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          user = FirebaseAuth.instance.currentUser;
        }
      }

      if (prefs.getBool('guard_logged_in') == true) {
        final savedId = (prefs.getString('guard_id') ?? '').trim().toUpperCase();
        if (savedId.isNotEmpty) {
          Map<String, dynamic>? data;
          var answered = false;
          try {
            final officerDoc = await FirebaseFirestore.instance
                .collection('satpam_officers')
                .doc(savedId)
                .get()
                .timeout(const Duration(seconds: 6));
            answered = true;
            data = officerDoc.exists ? officerDoc.data() : null;
          } catch (_) {}

          final stillValid = answered ? (data != null && data['active'] == true) : true;
          if (stillValid) {
            if (FirebaseAuth.instance.currentUser != null) {
              await FirebaseAuth.instance.signOut();
            }

            store.guard = true;
            store.email = savedId;
            store.guardPos = (data?['post'] as String?) ?? prefs.getString('guard_pos') ?? posList[0];
            await store.load();
            final officialName = (data?['name'] as String?)?.trim() ?? '';
            if (officialName.isNotEmpty) {
              store.customName = officialName;
            }

            if (!mounted) return;
            setState(() {
              _resolvedNext = const GuardShell();
              _alreadyLoggedIn = true;
            });
            return;
          }
        }
        await prefs.remove('guard_logged_in');
        await prefs.remove('guard_id');
        await prefs.remove('guard_pos');
      }

      if (user != null && user.email != null) {
        final email = user.email!.toLowerCase();
        var role = prefs.getString('user_role') ?? 'student';
        var blocked = false;
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 6));
          final data = doc.data();
          if (data != null) {
            blocked = data['blocked'] == true;
            role = (data['role'] as String?) ?? role;
            await prefs.setString('user_role', role);
          }
        } catch (_) {}

        if (email == 'admin@unesa.ac.id') {
          role = 'admin';
          await prefs.setString('user_role', 'admin');
        }

        var unverified = false;
        if (!blocked && role != 'admin') {
          var verified = user.emailVerified;
          if (!verified) {
            try {
              await user.reload();
              verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
            } catch (_) {}
          }
          unverified = !verified;
        }

        if (blocked || unverified) {
          await FirebaseAuth.instance.signOut();
          await prefs.remove('user_role');
        } else {
          store.guard = false;
          store.email = email;
          await store.load();

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
      loadingSession: _resolvedNext == null,
    );
  }
}

class _CampusSkylinePainter extends CustomPainter {
  final Color color;
  const _CampusSkylinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.55)
      ..lineTo(w * 0.08, h * 0.55)
      ..lineTo(w * 0.08, h * 0.35)
      ..lineTo(w * 0.14, h * 0.25)
      ..lineTo(w * 0.20, h * 0.35)
      ..lineTo(w * 0.20, h * 0.60)
      ..lineTo(w * 0.30, h * 0.60)
      ..lineTo(w * 0.30, h * 0.42)
      ..lineTo(w * 0.38, h * 0.42)
      ..lineTo(w * 0.38, h * 0.22)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.62, h * 0.22)
      ..lineTo(w * 0.62, h * 0.42)
      ..lineTo(w * 0.70, h * 0.42)
      ..lineTo(w * 0.70, h * 0.58)
      ..lineTo(w * 0.80, h * 0.58)
      ..lineTo(w * 0.80, h * 0.32)
      ..lineTo(w * 0.86, h * 0.24)
      ..lineTo(w * 0.92, h * 0.32)
      ..lineTo(w * 0.92, h * 0.52)
      ..lineTo(w, h * 0.52)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CampusSkylinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class AuthScaffold extends StatelessWidget {
  final String badgeText;
  final String title;
  final String subtitle;
  final double maxWidth;
  final bool showSkylineFooter;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    this.maxWidth = 480,
    this.showSkylineFooter = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final subColor = dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final screenW = MediaQuery.of(context).size.width;
    final titleFontSize = (screenW * 0.066).clamp(22.0, 27.0);

    return Scaffold(
      body: Column(
        children: [
          CartoonHeader(
            height: 220,
            bottomRadius: 30,
            showBuilding: true,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Navigator.canPop(context))
                      TapScale(
                        onTap: () => Navigator.pop(context),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: dark
                                ? const Color(0xFF111D30).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.94),
                            foregroundColor: dark ? Colors.white : _kNavyUnesa,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF111D30).withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: dark
                                ? const Color(0xFF1E3250)
                                : const Color(0xFFDCE6F2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _kToskaMain,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'UNESA LOST & FOUND PORTAL',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: dark ? Colors.white : _kNavyUnesa,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (showSkylineFooter)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 92,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CampusSkylinePainter(
                          dark
                              ? const Color(0xFF1E3250).withValues(alpha: 0.55)
                              : const Color(0xFFCBD5E1).withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FadeSlideIn(
                            index: 0,
                            child: Column(
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.85, end: 1.0),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutBack,
                                  builder: (_, scale, child) =>
                                      Transform.scale(scale: scale, child: child),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0xFF111D30) : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const AppLogo(size: 58),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: dark ? const Color(0xFF132F3B) : kMintSoft,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: dark
                                          ? const Color(0xFF22B8CF).withValues(alpha: 0.35)
                                          : _kToskaMain.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    badgeText.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: dark ? const Color(0xFF38BDF8) : _kToskaMain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: dark ? Colors.white : _kSlateTitle,
                                      letterSpacing: -0.5,
                                      height: 1.2,
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
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: subColor,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                              ],
                            ),
                          ),
                          ...children,
                          if (showSkylineFooter) ...[
                            const SizedBox(height: 26),
                            Text(
                              'Bersama menjaga barang,\nuntuk lingkungan kampus yang lebih aman',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: subColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
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

  Widget _roleCard({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String roleTag,
    required String title,
    required String sub,
    required String btnLabel,
    required bool guard,
    required Color accent,
  }) {
    final dark = isDark(context);
    final effectiveAccent = dark
        ? (guard ? const Color(0xFF60A5FA) : const Color(0xFF22B8CF))
        : accent;

    return FadeSlideIn(
      index: index,
      child: InteractiveCard(
        accentColor: effectiveAccent,
        padding: const EdgeInsets.all(18),
        onTap: () => Navigator.push(context, smoothRoute(LoginScreen(guard: guard))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: dark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: effectiveAccent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Icon(icon, color: effectiveAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleTag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: effectiveAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: dark ? Colors.white : _kSlateTitle,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: mutedC(context),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sub,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: mutedC(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11.5, horizontal: 14),
              decoration: BoxDecoration(
                color: dark
                    ? (guard ? const Color(0xFF1E3A8A) : const Color(0xFF0E7490))
                    : accent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      btnLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: Colors.white,
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
      badgeText: 'CampusFind UNESA',
      title: 'Selamat Datang!',
      subtitle: 'Pilih jenis akun untuk melanjutkan layanan pelaporan & klaim barang kampus.',
      maxWidth: isWide ? 840 : 480,
      showSkylineFooter: true,
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
                  roleTag: 'MAHASISWA UNESA',
                  title: 'Login Mahasiswa',
                  sub: 'Masuk dengan akun mahasiswa UNESA (@mhs.unesa.ac.id) untuk melapor & mengklaim barang.',
                  btnLabel: 'Masuk Mahasiswa UNESA',
                  guard: false,
                  accent: _kToskaMain,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _roleCard(
                  context: context,
                  index: 2,
                  icon: Icons.verified_user_rounded,
                  roleTag: 'PETUGAS KEAMANAN',
                  title: 'Login Satpam',
                  sub: 'Masuk dengan akun petugas keamanan pos UNESA untuk verifikasi laporan & serah terima barang.',
                  btnLabel: 'Masuk sebagai Satpam',
                  guard: true,
                  accent: _kNavyUnesa,
                ),
              ),
            ],
          )
        else ...[
          _roleCard(
            context: context,
            index: 1,
            icon: Icons.school_rounded,
            roleTag: 'MAHASISWA UNESA',
            title: 'Login Mahasiswa',
            sub: 'Masuk dengan akun mahasiswa UNESA (@mhs.unesa.ac.id) untuk melapor & mengklaim barang.',
            btnLabel: 'Masuk Mahasiswa UNESA',
            guard: false,
            accent: _kToskaMain,
          ),
          const SizedBox(height: 14),
          _roleCard(
            context: context,
            index: 2,
            icon: Icons.verified_user_rounded,
            roleTag: 'PETUGAS KEAMANAN',
            title: 'Login Satpam',
            sub: 'Masuk dengan akun petugas keamanan pos UNESA untuk verifikasi laporan & serah terima barang.',
            btnLabel: 'Masuk sebagai Satpam',
            guard: true,
            accent: _kNavyUnesa,
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
  String? pos;

  static const _defaultGuardPassword = 'satpam123';

  bool get _isAdminEmailInput => idC.text.trim().contains('@');

  @override
  void initState() {
    super.initState();
    idC.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    idC.dispose();
    passC.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final email = googleUser.email.trim().toLowerCase();

      if (!email.endsWith('@mhs.unesa.ac.id')) {
        await googleSignIn.signOut();
        if (mounted) {
          setState(() => loading = false);
          _showError('Wajib menggunakan akun Google resmi mahasiswa UNESA (@mhs.unesa.ac.id).');
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final uid = firebaseUser.uid;
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(uid);
      final doc = await userRef.get();

      if (doc.exists && doc.data()?['blocked'] == true) {
        await FirebaseAuth.instance.signOut();
        await googleSignIn.signOut();
        if (mounted) {
          setState(() => loading = false);
          _showError('Akun Anda dibekukan sementara oleh Admin Supervisor.');
        }
        return;
      }

      String nim = '';
      final usernamePart = email.split('@').first;
      if (RegExp(r'^\d+$').hasMatch(usernamePart)) {
        nim = usernamePart;
      }

      final photoUrl = googleUser.photoUrl ?? firebaseUser.photoURL ?? '';
      String displayName = googleUser.displayName?.trim() ?? firebaseUser.displayName?.trim() ?? '';
      if (displayName.isEmpty) {
        displayName = usernamePart;
      }

      String role = 'student';
      if (!doc.exists) {
        await userRef.set({
          'email': email,
          'name': displayName,
          'nim': nim,
          'role': 'student',
          'blocked': false,
          'photoUrl': photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final userData = doc.data();
        role = (userData?['role'] as String?) ?? 'student';
        final savedName = (userData?['name'] as String?) ?? '';
        if (savedName.isNotEmpty) displayName = savedName;
        final savedNim = (userData?['nim'] as String?) ?? '';
        if (savedNim.isNotEmpty) nim = savedNim;
        if (photoUrl.isNotEmpty) {
          await userRef.set({'photoUrl': photoUrl}, SetOptions(merge: true));
        }
      }

      final finalPhotoUrl = photoUrl.isNotEmpty ? photoUrl : (doc.data()?['photoUrl'] as String? ?? '');

      store.guard = false;
      store.email = email;
      await store.login(
        uid: uid,
        name: displayName,
        email: email,
        nim: nim,
        role: role,
        photoUrl: finalPhotoUrl,
      );
      await store.load();

      if (!mounted) return;
      final nav = Navigator.of(context);

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (role == 'admin') {
        nav.pushAndRemoveUntil(
          smoothRoute(AdminDashboardScreen(adminEmail: email)),
              (r) => false,
        );
      } else {
        final seen = prefs.getBool('tutorial_seen') ?? false;
        final Widget next = seen ? const StudentShell() : const TutorialScreen();
        nav.pushAndRemoveUntil(smoothRoute(next), (r) => false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal masuk dengan Google: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final db = FirebaseFirestore.instance;

      if (widget.guard) {
        final rawId = idC.text.trim();
        final inputPass = passC.text.trim();

        // 1. Jika input berupa Email (misal: admin@unesa.ac.id) -> Cek login Admin
        if (rawId.contains('@')) {
          final emailInput = rawId.toLowerCase();
          try {
            final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailInput,
              password: inputPass,
            );
            final user = cred.user;
            if (user == null) return;

            final doc = await db.collection('users').doc(user.uid).get();
            final data = doc.data();
            final role = (data?['role'] as String?) ??
                (emailInput == 'admin@unesa.ac.id' ? 'admin' : 'student');

            if (role != 'admin') {
              await FirebaseAuth.instance.signOut();
              _showError('Akses ditolak! Hanya akun Admin Supervisor atau ID Satpam yang dapat masuk.');
              return;
            }

            final displayName =
            (data?['name'] as String?)?.trim().isNotEmpty == true
                ? data!['name'].toString().trim()
                : 'Admin Supervisor';

            await prefs.remove('guard_logged_in');
            await prefs.remove('guard_id');
            await prefs.remove('guard_pos');
            await prefs.setString('user_role', 'admin');

            store.guard = false;
            store.email = emailInput;
            await store.login(
              uid: user.uid,
              name: displayName,
              email: emailInput,
              role: 'admin',
            );
            await store.load();

            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              smoothRoute(AdminDashboardScreen(adminEmail: emailInput)),
                  (r) => false,
            );
            return;
          } on FirebaseAuthException catch (e) {
            _showError(
              e.code == 'invalid-credential' ||
                  e.code == 'wrong-password' ||
                  e.code == 'user-not-found'
                  ? 'Email atau password admin salah.'
                  : 'Gagal masuk admin: ${e.message ?? e.code}',
            );
            return;
          }
        }

        // 2. Jika input berupa ID Petugas Satpam (misal: SATPAM01) -> Cek login Satpam
        final guardId = rawId.toUpperCase();
        final officerDoc = await db.collection('satpam_officers').doc(guardId).get();

        if (!officerDoc.exists || officerDoc.data() == null) {
          _showError('ID Petugas "$guardId" tidak terdaftar! Hubungi Admin Supervisor untuk pendaftaran ID resmi.');
          return;
        }

        final data = officerDoc.data()!;
        if (data['active'] != true) {
          _showError('Akun petugas "$guardId" sedang dinonaktifkan oleh Admin Supervisor.');
          return;
        }

        final customDocPass = (data['pin'] ?? data['password'] ?? '').toString().trim();
        final expectedPass = customDocPass.isNotEmpty ? customDocPass : _defaultGuardPassword;
        if (inputPass != expectedPass) {
          _showError('Password Satpam salah! Pastikan Anda memasukkan password petugas yang benar.');
          return;
        }

        final registeredPos = (data['post'] as String?) ?? '';
        if (registeredPos.isNotEmpty && registeredPos != pos) {
          _showError('ID "$guardId" hanya terdaftar untuk bertugas di $registeredPos, bukan di $pos.');
          return;
        }

        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }

        final officialName = (data['name'] as String?)?.trim() ?? '';
        store.guard = true;
        store.email = guardId;
        store.guardPos = pos!;
        if (officialName.isNotEmpty) {
          store.customName = officialName;
        }

        await prefs.remove('user_role');
        await prefs.setBool('guard_logged_in', true);
        await prefs.setString('guard_id', guardId);
        await prefs.setString('guard_pos', pos!);
        await store.load();
        if (officialName.isNotEmpty) {
          store.customName = officialName;
        }

        final seen = prefs.getBool('guard_tutorial_seen') ?? false;
        if (!mounted) return;
        final Widget next = seen ? const GuardShell() : const TutorialScreen();
        Navigator.pushAndRemoveUntil(context, smoothRoute(next), (r) => false);
        return;
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _benefitRow(BuildContext context, IconData icon, String text) {
    final dark = isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF132F3B) : kMintSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 15,
              color: dark ? const Color(0xFF38BDF8) : _kToskaMain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guard;
    final dark = isDark(context);
    final availablePos = store.availablePosList;

    if (!g) {
      return AuthScaffold(
        badgeText: 'Autentikasi Mahasiswa',
        title: 'Login Mahasiswa',
        subtitle: 'Masuk dengan akun Google resmi mahasiswa UNESA (@mhs.unesa.ac.id).',
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
                    color: Colors.black.withValues(alpha: dark ? 0.25 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF132F3B) : kMintSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dark
                            ? const Color(0xFF22B8CF).withValues(alpha: 0.30)
                            : _kToskaMain.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF0E7490) : _kToskaMain,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.alternate_email_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Kampus Resmi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: dark ? Colors.white : _kSlateTitle,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'nama.nim@mhs.unesa.ac.id',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: dark ? const Color(0xFF38BDF8) : _kToskaMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _benefitRow(context, Icons.edit_note_rounded,
                      'Buat laporan barang hilang & temuan dengan cepat'),
                  _benefitRow(context, Icons.auto_awesome_rounded,
                      'Notifikasi otomatis jika barang yang cocok ditemukan'),
                  _benefitRow(context, Icons.qr_code_scanner_rounded,
                      'Verifikasi & klaim aman melalui QR Pos Satpam'),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: loading
                        ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                          child: CircularProgressIndicator(color: _kToskaMain)),
                    )
                        : SizedBox(
                      key: const ValueKey('btn_google_login'),
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login_rounded, size: 20),
                        label: const Text(
                          'Pilih Akun Google UNESA',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          dark ? const Color(0xFF0E7490) : _kToskaMain,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 14, color: mutedC(context)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Terhubung otomatis dengan identitas mahasiswa UNESA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: mutedC(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AuthScaffold(
      badgeText: 'Akses Satpam UNESA',
      title: 'Login Satpam',
      subtitle: 'Masukkan ID Petugas resmi, password petugas, dan pilih lokasi pos penjagaan.',
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
                  color: Colors.black.withValues(alpha: dark ? 0.25 : 0.05),
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
                    'Username / ID Petugas',
                    'Contoh: SATPAM01',
                    controller: idC,
                    icon: Icons.badge_outlined,
                    keyboard: TextInputType.emailAddress,
                    helper: 'ID Petugas diterbitkan oleh Admin Supervisor',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      return null;
                    },
                  ),
                  const Text('Password',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: passC,
                    obscureText: hide,
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password petugas pos',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                            hide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18),
                        onPressed: () => setState(() => hide = !hide),
                      ),
                    ),
                  ),
                  if (!_isAdminEmailInput) ...[
                    const SizedBox(height: 14),
                    AppDropdown(
                      'Bertugas di Pos',
                      'Pilih pos satpam',
                      availablePos,
                      availablePos.contains(pos) ? pos : null,
                          (v) => setState(() => pos = v),
                      isRequired: true,
                    ),
                  ],
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: loading
                        ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                          child: CircularProgressIndicator(color: _kNavyUnesa)),
                    )
                        : SizedBox(
                      key: const ValueKey('btn_satpam_login'),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _login,
                        icon: const Icon(Icons.verified_user_rounded, size: 19),
                        label: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          dark ? const Color(0xFF1E3A8A) : _kNavyUnesa,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: mutedC(context)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Hanya untuk petugas keamanan UNESA yang terotorisasi',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: mutedC(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
    (Icons.mark_email_read_rounded, 'Masuk dengan Email Mahasiswa', 'Login memakai email resmi mahasiswa UNESA (@mhs.unesa.ac.id) untuk menggunakan aplikasi.'),
    (Icons.edit_note_rounded, 'Buat Laporan', 'Di menu Laporan pilih Lapor Kehilangan atau Lapor Barang Ditemukan. Upload foto barang, AI akan mengenali nama, jenis, warna, dan ciri-ciri. Lalu pilih pos satpam.'),
    (Icons.qr_code_2_rounded, 'Verifikasi QR Satpam', 'Buka laporan yang tersimpan kapan saja untuk memindai QR pos satpam. Setelah disetujui, laporanmu tampil di Beranda.'),
    (Icons.auto_awesome_rounded, 'Notifikasi Pencocokan', 'Setelah laporan hilangmu disetujui, sistem mencocokkan otomatis dengan barang temuan. Notifikasi berbunyi dan menampilkan barang yang paling mirip beserta persentase kecocokan.'),
    (Icons.verified_rounded, 'Klaim Barang', 'Buka barang temuan di Beranda atau Cari, lalu Ajukan Klaim dan sebutkan detail rahasianya. Pindai QR pos satpam saat verifikasi. Jika cocok dan disetujui, barang diserahkan kepadamu.'),
  ];

  static const guardPages = [
    (Icons.dashboard_customize_rounded, 'Menu Beranda Satpam', 'Di menu Beranda, pantau antrean verifikasi laporan barang masuk dan daftar klaim mahasiswa yang menunggu tindakan di pos jaga Anda.'),
    (Icons.qr_code_scanner_rounded, 'QR Barcode Pos Satpam', 'Gunakan menu QR Pos untuk menampilkan kode QR dinamis pos jaga agar dipindai mahasiswa saat menyerahkan barang temuan atau mengambil barang klaim.'),
    (Icons.fact_check_rounded, 'Verifikasi Detail Rahasia', 'Saat meninjau klaim, aplikasi menampilkan kotak perbandingan antara ciri barang pada laporan dengan jawaban pengklaim secara berdampingan.'),
    (Icons.task_alt_rounded, 'Keputusan & Serah Terima', 'Tekan tombol "Setujui Klaim & Serahkan Barang" jika data cocok, atau tombol "Tolak Klaim" jika data tidak sesuai.'),
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
    final dark = isDark(context);

    return PopScope(
      canPop: widget.fromProfile && page == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (page > 0) {
          pc.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutQuart);
        } else {
          _finish();
        }
      },
      child: Scaffold(
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
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: (dark ? const Color(0xFF22B8CF) : _kToskaMain).withValues(alpha: 0.12),
                            child: Icon(
                              pages[i].$1,
                              size: 54,
                              color: dark ? const Color(0xFF38BDF8) : _kToskaMain,
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
                      decoration: BoxDecoration(
                        color: i == page
                            ? (dark ? const Color(0xFF22B8CF) : _kToskaMain)
                            : borderC(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ]),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (last) {
                          _finish();
                        } else {
                          pc.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutQuart);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark ? const Color(0xFF0E7490) : _kToskaMain,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        last
                            ? (widget.fromProfile ? 'Selesai' : 'Mulai Gunakan')
                            : 'Lanjut',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}