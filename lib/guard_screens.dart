import 'dart:async';
import 'package:flutter/material.dart';
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
    final pages = [
      GuardHome(onGo: (i) => setState(() => tab = i)),
      const GuardReportList(),
      const GuardScanScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (tab != 0) setState(() => tab = 0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: tab,
          children: [
            for (int i = 0; i < pages.length; i++)
              TickerMode(enabled: tab == i, child: pages[i]),
          ],
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
      ),
    );
  }
}

class GuardHome extends StatefulWidget {
  final void Function(int)? onGo;
  const GuardHome({super.key, this.onGo});
  @override
  State<GuardHome> createState() => _GuardHomeState();
}

class _GuardHomeState extends State<GuardHome> {
  int queueTab = 0;

  Widget _stat(BuildContext context, int val, String label, Color accent) {
    final dark = isDark(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF13291F) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dark ? const Color(0xFF2E5A44) : const Color(0xFFD1E7DD),
          ),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.black : kDeep).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark ? Colors.white : accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            val,
            style: TextStyle(
              color: dark ? Colors.white : kForestSolid,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]),
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
            color: dark ? const Color(0xFF13291F) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? const Color(0xFF2E5A44) : const Color(0xFFD1E7DD),
            ),
            boxShadow: [
              BoxShadow(
                color: (dark ? Colors.black : kDeep).withValues(alpha: 0.04),
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
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : accent),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: mutedC(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyQueueCard(BuildContext context, String text) {
    final dark = isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF13291F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? const Color(0xFF2E5A44) : const Color(0xFFD1E7DD),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: kEmeraldSolid, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mutedC(context)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: queueTab == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      if (queueTab != 0) setState(() => queueTab = 0);
    },
    child: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final dark = isDark(context);
        final all = store.reports;
        final wait = all
            .where((r) => r.status == stWait && r.pos == store.guardPos)
            .toList();
        final pend = store.claims
            .where((c) =>
        c.status == 'Menunggu' &&
            store.find(c.reportId)?.pos == store.guardPos)
            .toList();
        final duty = store.dutyForPos(store.guardPos);
        final me = store.currentGuardOfficer;
        final isDisabledByAdmin = me != null && !me.active;
        final activeShiftText =
            me?.shift ?? duty?.shift ?? currentShiftLabel();
        final inShiftNow = isShiftActiveNow(activeShiftText);

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            HomeHeader(
              name: store.name.isEmpty ? 'Petugas Pos' : store.name,
              subtitle: store.guardPos,
              onProfile: () => widget.onGo?.call(3),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FadeSlideIn(index: 0, child: HomeHoursCard()),
                    const SizedBox(height: 20),
                    sectionHeading(context, 'Ringkasan Pos Satpam'),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      index: 1,
                      child: Row(children: [
                        _stat(context, all.length, 'Total Laporan',
                            kEmeraldSolid),
                        _stat(context, wait.length, 'Verifikasi',
                            Colors.amber.shade800),
                        _stat(context, pend.length, 'Klaim',
                            const Color(0xFF2563EB)),
                      ]),
                    ),
                    if (pend.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => queueTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: dark ? 0.22 : 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded,
                                  color: Color(0xFF2563EB), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ada ${pend.length} pengajuan klaim menunggu verifikasi di pos ini',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? const Color(0xFF93C5FD)
                                        : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Kartu Penugasan Pos Otomatis (Ditetapkan Admin)
                    FadeSlideIn(
                      index: 2,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF13291F)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDisabledByAdmin
                                ? Colors.redAccent
                                : (dark
                                ? const Color(0xFF2E5A44)
                                : const Color(0xFFD1E7DD)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (isDisabledByAdmin
                                    ? Colors.redAccent
                                    : kEmeraldSolid)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isDisabledByAdmin
                                    ? Icons.block_rounded
                                    : Icons.shield_rounded,
                                color: isDisabledByAdmin
                                    ? Colors.redAccent
                                    : kEmeraldSolid,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.guardPos,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Petugas: ${store.name} • $activeShiftText',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: mutedC(context)),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isDisabledByAdmin
                                        ? 'Status akun dinonaktifkan oleh Admin'
                                        : (inShiftNow
                                        ? '● Jadwal Jaga Aktif (Otomatis sesuai jadwal Admin)'
                                        : '🕒 Di luar jam shift terjadwal (Tetap memantau pos)'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDisabledByAdmin
                                          ? Colors.redAccent
                                          : (inShiftNow
                                          ? (dark
                                          ? const Color(0xFF6EE7B7)
                                          : kEmeraldSolid)
                                          : Colors.amber.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    sectionHeading(context, 'Antrean Tugas'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF13291F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dark
                              ? const Color(0xFF2E5A44)
                              : const Color(0xFFD1E7DD),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => queueTab = 0),
                              child: AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: queueTab == 0
                                      ? kEmeraldSolid
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Verifikasi (${wait.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: queueTab == 0
                                        ? Colors.white
                                        : mutedC(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => queueTab = 1),
                              child: AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: queueTab == 1
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Klaim (${pend.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: queueTab == 1
                                        ? Colors.white
                                        : mutedC(context),
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
                        _emptyQueueCard(context,
                            'Tidak ada antrean verifikasi di pos ini.')
                      else
                        for (final r in wait)
                          _uniformQueueCard(
                            context,
                            icon: Icons.inventory_2_outlined,
                            accent: Colors.amber.shade800,
                            title: r.name,
                            subtitle:
                            '${r.typeLabel} • ${r.owner.split('@').first}',
                            badge: 'Verifikasi',
                            onTap: () => openReport(context, r),
                          ),
                    ] else ...[
                      if (pend.isEmpty)
                        _emptyQueueCard(context,
                            'Tidak ada antrean klaim di pos ini.')
                      else
                        for (final c in pend)
                          Builder(builder: (context) {
                            final rep = store.find(c.reportId);
                            return _uniformQueueCard(
                              context,
                              icon: Icons.verified_user_outlined,
                              accent: const Color(0xFF2563EB),
                              title: rep?.name ?? c.reportId,
                              subtitle:
                              'Pengklaim: ${c.claimer.split('@').first}',
                              badge: 'Klaim',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ClaimReviewScreen(c))),
                            );
                          }),
                    ],
                    const SizedBox(height: 22),
                    const HomeNewsSection(),
                  ]),
            ),
          ],
        );
      },
    ),
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
            .where((r) =>
        (f == 'Semua' || r.typeLabel == f || r.status == f) &&
            (p == 'Semua Pos' || r.pos == p))
            .toList();
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const BandHeader('Daftar Laporan',
                subtitle: 'Pantau seluruh laporan & status pos'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionHeading(context, 'Filter Laporan'),
                            const SizedBox(height: 10),
                            FilterChips(
                                const [
                                  'Semua',
                                  'Hilang',
                                  'Ditemukan',
                                  stWait,
                                  stClaimed,
                                  stDone,
                                  stRejected,
                                ],
                                f,
                                    (v) => setState(() => f = v)),
                            const SizedBox(height: 8),
                            FilterChips(
                                ['Semua Pos', ...store.availablePosList],
                                p,
                                    (v) => setState(() => p = v)),
                          ]),
                    ),
                    const SizedBox(height: 14),
                    sectionHeading(context, 'Arsip Laporan',
                        trailing: '${list.length} data'),
                    const SizedBox(height: 10),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Center(
                            child: Text(
                                'Tidak ada laporan pada filter ini.',
                                style: TextStyle(color: mutedC(context)))),
                      ),
                    for (var i = 0; i < list.length; i++)
                      FadeSlideIn(
                        index: i + 1,
                        child: ReportTile(
                            list[i], () => openReport(context, list[i])),
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
      if (store.posTokenPos != store.guardPos ||
          store.posTokenExp == null ||
          DateTime.now().isAfter(store.posTokenExp!)) {
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
      final left =
      (store.posTokenExp ?? DateTime.now()).difference(DateTime.now());
      final expired = left.isNegative || left.inSeconds <= 0;
      final progress = (left.inSeconds / 300.0).clamp(0.0, 1.0);
      final payload = 'CF|POS|${store.guardPos}|${store.posToken}';
      final code = '${store.guardPos}\n${store.posToken}';
      final dark = isDark(context);

      final bgCol = dark ? kDeep : softC(context);
      final appBg = dark ? kDeep : cardC(context);
      final textCol = dark ? Colors.white : kForestSolid;
      final chipBg = dark ? const Color(0xFF13291F) : Colors.white;

      return Scaffold(
        backgroundColor: bgCol,
        appBar: AppBar(
          backgroundColor: appBg,
          foregroundColor: textCol,
          elevation: dark ? 0 : 1,
          title: Text('QR Barcode Pos Satpam',
              style: TextStyle(
                  fontSize: 16,
                  color: textCol,
                  fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            child: FadeSlideIn(
              index: 0,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: dark
                            ? const Color(0xFF2E5A44)
                            : const Color(0xFFD1E7DD)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_rounded,
                        color: kEmeraldSolid, size: 18),
                    const SizedBox(width: 6),
                    Text(store.guardPos,
                        style: TextStyle(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 16),
                if (_initializing || store.posToken.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: kEmeraldSolid),
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0)
                            .animate(anim),
                        child: child,
                      ),
                    ),
                    child: Container(
                      key: ValueKey(store.posToken),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: dark ? 0.35 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFD1E7DD)),
                      ),
                      child: QrImageView(
                          data: payload,
                          size: 185,
                          backgroundColor: Colors.white),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textCol,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                        Colors.amber.shade700.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_rounded,
                          size: 15, color: Colors.amber.shade800),
                      const SizedBox(width: 5),
                      Text(
                        expired
                            ? 'Kedaluwarsa'
                            : 'Berlaku ${_mmss(left)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: dark
                                ? Colors.amber.shade200
                                : Colors.amber.shade900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      color: kEmeraldSolid,
                      backgroundColor: dark
                          ? Colors.white24
                          : const Color(0xFFD1E7DD),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                    'Perbarui QR Barcode Baru',
                        () => store.issuePosToken(store.guardPos),
                    outlined: true),
              ]),
            ),
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------ tinjau klaim (satpam)
class ClaimReviewScreen extends StatefulWidget {
  final Claim c;
  final bool review;
  const ClaimReviewScreen(this.c, {super.key, this.review = false});

  @override
  State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
}

class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
  final _nimCtrl = TextEditingController();

  @override
  void dispose() {
    _nimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final c = widget.c;
      final r = store.find(c.reportId);
      return Scaffold(
        appBar: AppBar(
            title: const Text('Verifikasi Klaim',
                style: TextStyle(fontSize: 16))),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 24 + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            if (r != null)
              FadeSlideIn(
                index: 0,
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                          width: 80, height: 80, child: ReportPhoto(r))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                          Text('${r.id}\n${r.pos}',
                              style: TextStyle(
                                  fontSize: 11, color: mutedC(context))),
                          const SizedBox(height: 6),
                          StatusChip(c.status),
                        ]),
                  ),
                ]),
              ),
            const Divider(height: 26),
            FadeSlideIn(
              index: 1,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(Icons.person_outline_rounded, 'Pengklaim',
                        c.claimer),
                    InfoRow(Icons.tag_rounded, 'Kode Klaim', c.id),
                    InfoRow(Icons.calendar_today_outlined, 'Diajukan',
                        fmtDate(c.date)),
                    if (c.claimerNim.isNotEmpty)
                      InfoRow(Icons.badge_outlined, 'NIM Pengambil',
                          c.claimerNim),
                    const SizedBox(height: 6),
                    sectionHeading(context, 'Pencocokan Ciri Barang'),
                    const SizedBox(height: 10),
                    SecretBox('Deskripsi & ciri-ciri pada laporan',
                        r?.description ?? '-'),
                    SecretBox('Jawaban pengklaim', c.answer,
                        color: Colors.orange.shade800),
                    if (c.proof.isNotEmpty)
                      InfoRow(Icons.description_outlined, 'Bukti tambahan',
                          c.proof),
                    if (c.photo != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: PhotoImage(c.photo!))),
                    ],
                    const SizedBox(height: 16),
                    if (c.status == 'Menunggu' && widget.review) ...[
                      AppField(
                        'NIM / Nomor Identitas Pengambil (Cek KTM)',
                        'Masukkan NIM mahasiswa saat tatap muka di pos',
                        controller: _nimCtrl,
                        icon: Icons.badge_outlined,
                      ),
                      PrimaryButton('Setujui Klaim & Serahkan Barang', () {
                        store.approveClaim(c,
                            claimerNim: _nimCtrl.text.trim());
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HandoverDoneScreen(c)));
                      }),
                      const SizedBox(height: 10),
                      PrimaryButton('Tolak Klaim (tidak cocok)', () {
                        final m = ScaffoldMessenger.of(context);
                        store.rejectClaim(c);
                        Navigator.pop(context);
                        m.showSnackBar(
                            const SnackBar(content: Text('Klaim ditolak')));
                      }, outlined: true),
                    ] else if (c.status == 'Menunggu')
                      Text(
                        'Untuk menyetujui, tampilkan QR Barcode Pos Satpam di menu QR Pos agar dipindai oleh pengklaim.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: mutedC(context)),
                      ),
                  ]),
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
    child:
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(width: 12),
      Flexible(
          child: Text(v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final r = store.find(c.reportId);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Serah Terima Barang',
              style: TextStyle(fontSize: 16))),
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
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const CircleAvatar(
                  radius: 36,
                  backgroundColor: kEmeraldSolid,
                  child:
                  Icon(Icons.check_rounded, size: 40, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            const Text('Serah Terima Berhasil!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            FadeSlideIn(
              index: 1,
              child: EmeraldGlass(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                child: Column(children: [
                  _row('Kode Klaim', c.id),
                  _row('Barang', r?.name ?? '-'),
                  _row('Penerima', c.claimer),
                  if (c.claimerNim.isNotEmpty)
                    _row('NIM / KTM', c.claimerNim),
                  _row('Waktu', fmtDate(DateTime.now())),
                  _row('Petugas', '${store.name}\n${store.guardPos}'),
                ]),
              ),
            ),
            const Spacer(),
            PrimaryButton('Kembali ke Dashboard',
                    () => Navigator.popUntil(context, (r) => r.isFirst)),
          ]),
        ),
      ),
    );
  }
}