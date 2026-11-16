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

class GuardHome extends StatelessWidget {
  const GuardHome({super.key});

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
          style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800),
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
      builder: (ctx) => Padding(
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
    );
  }

  Widget _guardHeader(BuildContext context) {
    final dark = isDark(context);
    final badgeBg = dark
        ? Colors.black.withValues(alpha: 0.50)
        : Colors.black.withValues(alpha: 0.35);
    final badgeBorder = dark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.35);

    return CartoonHeader(
      height: 195,
      bx: .82,
      bs: .45,
      groundY: .92,
      sunX: .55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 110,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    dark
                        ? Colors.black.withValues(alpha: 0.65)
                        : Colors.black.withValues(alpha: 0.40),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: FadeSlideIn(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const AppLogo(size: 32),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CampusFind',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1.5)),
                                ],
                              ),
                            ),
                            Text(
                              'UNESA Security Guard',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: badgeBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Halo, ${store.name}! 🛡️',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Petugas Jaga - ${store.guardPos}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.92),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final all = store.reports;
      final wait = all.where((r) => r.status == stWait && r.pos == store.guardPos).toList();
      final pend = store.claims.where((c) => c.status == 'Menunggu' && store.find(c.reportId)?.pos == store.guardPos).toList();
      final verifiedAtPos = all.where((r) => r.pos == store.guardPos && r.status != stWait).take(4).toList();

      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 115),
        children: [
          _guardHeader(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FadeSlideIn(
                index: 1,
                child: Row(children: [
                  _stat(all.length, 'Total Laporan', const [kDeep, Color(0xFF14532D)]),
                  _stat(wait.length, 'Perlu Verifikasi', [Colors.orange.shade800, Colors.deepOrange.shade600]),
                  _stat(pend.length, 'Klaim Menunggu', [Colors.blue.shade800, Colors.indigo.shade600]),
                ]),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                index: 2,
                child: TapScale(
                  onTap: () => _switchPosModal(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: softC(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderC(context)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Flexible(
                              child: Text('Pos Tugas: ${store.guardPos}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                              child: Text('Ganti Pos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark(context) ? Colors.lightGreenAccent : kGreen)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text('Tunjukkan QR Barcode Pos di menu QR Pos saat pelapor/pengklaim datang.', style: TextStyle(fontSize: 11, color: mutedC(context), height: 1.35)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                index: 3,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Antrean Verifikasi Laporan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    if (wait.isNotEmpty) Text('${wait.length} antrean', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w800)),
                  ]),
                  Text('Laporan baru dari warga yang membutuhkan verifikasi fisik di pos.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                  const SizedBox(height: 10),
                  if (wait.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC(context))),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline_rounded, color: kGreen, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Tidak Ada Laporan Menunggu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('Semua laporan di ${store.guardPos} sudah terverifikasi.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                          ]),
                        ),
                      ]),
                    )
                  else
                    for (var i = 0; i < wait.length; i++)
                      FadeSlideIn(
                        index: i + 3,
                        child: ReportTile(wait[i], () => openReport(context, wait[i])),
                      ),
                ]),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                index: 4,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Klaim Menunggu Verifikasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    if (pend.isNotEmpty) Text('${pend.length} klaim', style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w800)),
                  ]),
                  Text('Klaim kepemilikan barang dari warga yang menunggu dicocokkan.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                  const SizedBox(height: 10),
                  if (pend.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC(context))),
                      child: Row(children: [
                        const Icon(Icons.assignment_turned_in_outlined, color: Colors.blue, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Tidak Ada Klaim Menunggu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('Belum ada klaim barang baru yang perlu diproses.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                          ]),
                        ),
                      ]),
                    )
                  else
                    for (var i = 0; i < pend.length; i++)
                      FadeSlideIn(
                        index: i + 4,
                        child: ClaimTile(pend[i], () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimReviewScreen(pend[i])))),
                      ),
                ]),
              ),
              if (verifiedAtPos.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text('Aktivitas Terakhir di Pos Ini', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                Text('Laporan yang sudah diproses di ${store.guardPos}.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                const SizedBox(height: 10),
                for (var i = 0; i < verifiedAtPos.length; i++)
                  FadeSlideIn(
                    index: i + 5,
                    child: ReportTile(verifiedAtPos[i], () => openReport(context, verifiedAtPos[i])),
                  ),
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
          padding: const EdgeInsets.only(bottom: 115),
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
      final subTextCol = dark ? Colors.white70 : mutedC(context);
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 115),
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tunjukkan QR Barcode ini ke pelapor/pengklaim. QR akan BERGANTI OTOMATIS setelah 1 warga memindai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextCol, fontSize: 12, height: 1.35),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton('Perbarui QR Barcode Baru', () => store.issuePosToken(store.guardPos), outlined: true),
                const SizedBox(height: 10),
                Text(
                  store.posSyncError != null
                      ? '⚠️ ${store.posSyncError}'
                      : (store.posSynced
                      ? '✅ QR tersinkron ke server (siap dipindai HP lain)'
                      : '⏳ Menyinkronkan QR ke server...'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: store.posSyncError != null
                        ? Colors.redAccent
                        : (store.posSynced
                        ? (dark ? Colors.lightGreenAccent : kGreen)
                        : subTextCol),
                  ),
                ),
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
          padding: const EdgeInsets.all(16),
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
                      Text('${r.id} • ${r.pos}', style: TextStyle(fontSize: 11, color: mutedC(context))),
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
              Text('Untuk menyetujui, minta pengklaim menampilkan QR Klaim lalu pindai di menu Scan QR.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: mutedC(context))),
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
      body: Padding(
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
                _row('Petugas', '${store.name} • ${store.guardPos}'),
              ]),
            ),
          ),
          const Spacer(),
          PrimaryButton('Kembali ke Dashboard', () => Navigator.popUntil(context, (r) => r.isFirst)),
        ]),
      ),
    );
  }
}