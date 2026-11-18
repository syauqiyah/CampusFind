import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'cartoon.dart';
import 'core.dart';
import 'profile_screen.dart';
import 'student_screens.dart';
import 'widgets.dart';

class GuardShell extends StatefulWidget {
  const GuardShell({super.key});
  @override
  State<GuardShell> createState() => _GuardShellState();
}

class _GuardShellState extends State<GuardShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      GuardHome(),
      GuardReportList(),
      GuardScanScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(tab),
          child: pages[tab],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final n = store.reports.where((r) => r.status == stWait).length +
              store.claims.where((c) => c.status == 'Menunggu').length;
          return FloatingNav(
            index: tab,
            onTap: (i) => setState(() => tab = i),
            centerTooltip: 'QR Pos Satpam',
            items: [
              NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Beranda', badge: n),
              const NavItem(Icons.list_alt_outlined, Icons.list_alt_rounded, 'Laporan'),
              const NavItem(Icons.qr_code_2_outlined, Icons.qr_code_2_rounded, 'QR Pos'),
              const NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
            ],
          );
        },
      ),
    );
  }
}

class GuardHome extends StatefulWidget {
  const GuardHome({super.key});
  @override
  State<GuardHome> createState() => _GuardHomeState();
}

class _GuardHomeState extends State<GuardHome> {
  int queueTab = 0; // 0 = Verifikasi Laporan, 1 = Verifikasi Klaim

  Widget _stat(int val, String label, List<Color> gradientColors) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedCounter(
          val,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  void _switchPosModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pilih Pos Satpam Tugas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final pos in posList)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Icon(Icons.location_on_rounded, color: store.guardPos == pos ? kGreen : Colors.grey),
                title: Text(pos, style: TextStyle(fontWeight: store.guardPos == pos ? FontWeight.w700 : FontWeight.w500)),
                trailing: store.guardPos == pos ? const Icon(Icons.check_circle_rounded, color: kGreen) : null,
                onTap: () {
                  store.guardPos = pos;
                  store.issuePosToken(pos);
                  Navigator.pop(ctx);
                },
              ),
          ]),
        ),
      ),
    );
  }

  Widget _guardHeader(BuildContext context) {
    final dark = isDark(context);
    final name = store.name.isEmpty ? 'Petugas Pos' : store.name;
    String? brandFont;
    try {
      brandFont = GoogleFonts.syne().fontFamily;
    } catch (_) {}

    return CartoonHeader(
      height: 240,
      bx: .5,
      bs: .52,
      groundY: .82,
      sunX: .82,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AppLogo(size: 50),
                  const SizedBox(width: 11),
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.68)
                                : Colors.white.withValues(alpha: 0.76),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: dark
                                  ? const Color(0xFF94A3B8).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: dark ? 0.32 : 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Campus',
                                    style: TextStyle(
                                      fontFamily: brandFont,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      height: 1.0,
                                      color: dark ? const Color(0xFF7DD3FC) : const Color(0xFF0B357A),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Find',
                                      style: TextStyle(
                                        fontFamily: brandFont,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        height: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Halo, $name! 🛡️ • ${store.guardPos}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uniformQueueCard(
      BuildContext context, {
        required IconData icon,
        required Color accent,
        required String title,
        required String subtitle,
        required String badge,
        required VoidCallback onTap,
      }) {
    final dark = isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: cardC(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderC(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.18 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: mutedC(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: mutedC(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyQueueCard(BuildContext context, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    decoration: BoxDecoration(
      color: cardC(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderC(context)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: kGreen, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedC(context)),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final all = store.reports;
      final wait = all.where((r) => r.status == stWait && r.pos == store.guardPos).toList();
      final pend = store.claims.where((c) => c.status == 'Menunggu' && store.find(c.reportId)?.pos == store.guardPos).toList();

      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _guardHeader(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FadeSlideIn(
                index: 1,
                child: Row(children: [
                  _stat(all.length, 'Total Laporan', const [kDeep, Color(0xFF14532D)]),
                  _stat(wait.length, 'Verifikasi', [Colors.orange.shade800, Colors.deepOrange.shade600]),
                  _stat(pend.length, 'Klaim', [Colors.blue.shade800, Colors.indigo.shade600]),
                ]),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 2,
                child: TapScale(
                  onTap: () => _switchPosModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: softC(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderC(context)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.shield_rounded, color: kGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          store.guardPos,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                        child: Text('Ganti Pos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark(context) ? Colors.lightGreenAccent : kGreen)),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: softC(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderC(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => queueTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: queueTab == 0 ? kGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Verifikasi (${wait.length})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: queueTab == 0 ? Colors.white : mutedC(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => queueTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: queueTab == 1 ? kGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Klaim (${pend.length})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: queueTab == 1 ? Colors.white : mutedC(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (queueTab == 0) ...[
                if (wait.isEmpty)
                  _emptyQueueCard(context, 'Tidak ada antrean verifikasi di pos ini.')
                else
                  for (final r in wait)
                    _uniformQueueCard(
                      context,
                      icon: Icons.inventory_2_outlined,
                      accent: Colors.orange.shade800,
                      title: r.name,
                      subtitle: '${r.typeLabel} • ${r.owner.split('@').first}',
                      badge: 'Verifikasi',
                      onTap: () => openReport(context, r),
                    ),
              ] else ...[
                if (pend.isEmpty)
                  _emptyQueueCard(context, 'Tidak ada antrean klaim di pos ini.')
                else
                  for (final c in pend)
                    Builder(builder: (context) {
                      final rep = store.find(c.reportId);
                      return _uniformQueueCard(
                        context,
                        icon: Icons.verified_user_outlined,
                        accent: const Color(0xFF2563EB),
                        title: rep?.name ?? c.reportId,
                        subtitle: 'Pengklaim: ${c.claimer.split('@').first}',
                        badge: 'Klaim',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimReviewScreen(c))),
                      );
                    }),
              ],
            ]),
          ),
        ],
      );
    },
  );
}

class GuardReportList extends StatefulWidget {
  const GuardReportList({super.key});
  @override
  State<GuardReportList> createState() => _GuardReportListState();
}

class _GuardReportListState extends State<GuardReportList> {
  String f = 'Semua', p = 'Semua Pos';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.reports
            .where((r) => (f == 'Semua' || r.typeLabel == f || r.status == f) && (p == 'Semua Pos' || r.pos == p))
            .toList();
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const BandHeader('Daftar Laporan', subtitle: 'Pantau seluruh laporan & status pos'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FadeSlideIn(
                  index: 0,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FilterChips(const ['Semua', 'Hilang', 'Ditemukan', stWait, stClaimed, stDone], f, (v) => setState(() => f = v)),
                    const SizedBox(height: 8),
                    FilterChips(['Semua Pos', ...posList], p, (v) => setState(() => p = v)),
                  ]),
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(child: Text('Tidak ada laporan pada filter ini.', style: TextStyle(color: mutedC(context)))),
                  ),
                for (var i = 0; i < list.length; i++)
                  FadeSlideIn(
                    index: i + 1,
                    child: ReportTile(list[i], () => openReport(context, list[i])),
                  ),
              ]),
            ),
          ],
        );
      },
    ),
  );
}

class GuardScanScreen extends StatefulWidget {
  const GuardScanScreen({super.key});
  @override
  State<GuardScanScreen> createState() => _GuardScanScreenState();
}

class _GuardScanScreenState extends State<GuardScanScreen> {
  Timer? _timer;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _syncOrCreateToken();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _initializing) return;
      if (store.posTokenExp == null || DateTime.now().isAfter(store.posTokenExp!)) {
        store.issuePosToken(store.guardPos);
      }
      setState(() {});
    });
  }

  Future<void> _syncOrCreateToken() async {
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (store.posToken.isEmpty ||
        store.posTokenPos != store.guardPos ||
        store.posTokenExp == null ||
        DateTime.now().isAfter(store.posTokenExp!)) {
      await store.issuePosToken(store.guardPos);
    }
    if (mounted) setState(() => _initializing = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mmss(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final left = (store.posTokenExp ?? DateTime.now()).difference(DateTime.now());
      final expired = left.isNegative || left.inSeconds <= 0;
      final progress = (left.inSeconds / 300.0).clamp(0.0, 1.0);
      final payload = 'CF|POS|${store.guardPos}|${store.posToken}';
      final code = '${store.guardPos}\n${store.posToken}';
      final dark = isDark(context);

      final bgCol = dark ? kDeep : softC(context);
      final appBg = dark ? kDeep : cardC(context);
      final textCol = dark ? Colors.white : kDeep;
      final chipBg = dark ? Colors.white.withValues(alpha: 0.12) : kGreen;

      return Scaffold(
        backgroundColor: bgCol,
        appBar: AppBar(
          backgroundColor: appBg,
          foregroundColor: textCol,
          elevation: dark ? 0 : 1,
          title: Text('QR Barcode Pos Satpam', style: TextStyle(fontSize: 16, color: textCol, fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            child: FadeSlideIn(
              index: 0,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_on_rounded, color: dark ? Colors.amber : Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(store.guardPos, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 16),
                if (_initializing || store.posToken.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Container(
                      key: ValueKey(store.posToken),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: dark ? Colors.transparent : borderC(context)),
                      ),
                      child: QrImageView(data: payload, size: 185, backgroundColor: Colors.white),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(code, textAlign: TextAlign.center, style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.timer_rounded, size: 16, color: kDeep),
                  backgroundColor: Colors.amber,
                  label: Text(expired ? 'Kedaluwarsa' : 'Berlaku ${_mmss(left)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      color: Colors.amber,
                      backgroundColor: dark ? Colors.white24 : borderC(context),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton('Perbarui QR Barcode Baru', () => store.issuePosToken(store.guardPos), outlined: true),
              ]),
            ),
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------ tinjau klaim (satpam)
class ClaimReviewScreen extends StatelessWidget {
  final Claim c;
  final bool review;
  const ClaimReviewScreen(this.c, {super.key, this.review = false});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final r = store.find(c.reportId);
      return Scaffold(
        appBar: AppBar(title: const Text('Verifikasi Klaim', style: TextStyle(fontSize: 16))),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            if (r != null)
              FadeSlideIn(
                index: 0,
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 80, height: 80, child: ReportPhoto(r))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('${r.id}\n${r.pos}', style: TextStyle(fontSize: 11, color: mutedC(context))),
                      const SizedBox(height: 6),
                      StatusChip(c.status),
                    ]),
                  ),
                ]),
              ),
            const Divider(height: 26),
            FadeSlideIn(
              index: 1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                InfoRow(Icons.person_outline_rounded, 'Pengklaim', c.claimer),
                InfoRow(Icons.tag_rounded, 'Kode Klaim', c.id),
                InfoRow(Icons.calendar_today_outlined, 'Diajukan', fmtDate(c.date)),
                const SizedBox(height: 6),
                const Text('Pencocokan Detail Rahasia', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                SecretBox('Detail rahasia pada laporan (pelapor & satpam)', r?.secret ?? '-'),
                SecretBox('Jawaban pengklaim', c.answer, color: Colors.orange.shade800),
                if (c.proof.isNotEmpty) InfoRow(Icons.description_outlined, 'Bukti tambahan', c.proof),
                if (c.photo != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 180, width: double.infinity, child: PhotoImage(c.photo!))),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            if (c.status == 'Menunggu' && review) ...[
              PrimaryButton('Setujui Klaim & Serahkan Barang', () {
                store.approveClaim(c);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HandoverDoneScreen(c)));
              }),
              const SizedBox(height: 10),
              PrimaryButton('Tolak Klaim (tidak cocok)', () {
                final m = ScaffoldMessenger.of(context);
                store.rejectClaim(c);
                Navigator.pop(context);
                m.showSnackBar(const SnackBar(content: Text('Klaim ditolak')));
              }, outlined: true),
            ] else if (c.status == 'Menunggu')
              Text(
                'Untuk menyetujui, tampilkan QR Barcode Pos Satpam di menu QR Pos agar dipindai oleh pengklaim.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: mutedC(context)),
              ),
          ],
        ),
      );
    },
  );
}

class HandoverDoneScreen extends StatelessWidget {
  final Claim c;
  const HandoverDoneScreen(this.c, {super.key});

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(width: 12),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final r = store.find(c.reportId);
    return Scaffold(
      appBar: AppBar(title: const Text('Serah Terima Barang', style: TextStyle(fontSize: 16))),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1.0),
              duration: const Duration(milliseconds: 520),
              curve: Curves.elasticOut,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: const CircleAvatar(radius: 36, backgroundColor: kGreen, child: Icon(Icons.check_rounded, size: 40, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            const Text('Serah Terima Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            FadeSlideIn(
              index: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(18), border: Border.all(color: borderC(context))),
                child: Column(children: [
                  _row('Kode Klaim', c.id),
                  _row('Barang', r?.name ?? '-'),
                  _row('Penerima', c.claimer),
                  _row('Waktu', fmtDate(DateTime.now())),
                  _row('Petugas', '${store.name}\n${store.guardPos}'),
                ]),
              ),
            ),
            const Spacer(),
            PrimaryButton('Kembali ke Dashboard', () => Navigator.popUntil(context, (r) => r.isFirst)),
          ]),
        ),
      ),
    );
  }
}