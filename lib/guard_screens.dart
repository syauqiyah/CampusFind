import 'dart:async';
import 'dart:io';
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
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: tab, children: const [GuardHome(), GuardReportList(), GuardScanScreen(), ProfileScreen()]),
    bottomNavigationBar: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final n = store.reports.where((r) => r.status == stWait).length + store.claims.where((c) => c.status == 'Menunggu').length;
        return FloatingNav(
          index: tab,
          onTap: (i) => setState(() => tab = i),
          items: [
            NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Beranda', badge: n),
            const NavItem(Icons.list_alt, Icons.list_alt, 'Laporan'),
            const NavItem(Icons.qr_code_2_outlined, Icons.qr_code_2, 'QR Pos'),
            const NavItem(Icons.person_outline, Icons.person, 'Profil'),
          ],
        );
      },
    ),
  );
}

class GuardHome extends StatelessWidget {
  const GuardHome({super.key});

  Widget _stat(String n, String l, Color c) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(n, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
          const Text('Pilih Pos Satpam Tugas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final pos in posList)
            ListTile(
              leading: Icon(Icons.location_on, color: store.guardPos == pos ? kGreen : Colors.grey),
              title: Text(pos, style: TextStyle(fontWeight: store.guardPos == pos ? FontWeight.bold : FontWeight.normal)),
              trailing: store.guardPos == pos ? const Icon(Icons.check, color: kGreen) : null,
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
          // 1. Lapisan Gradasi Adaptif agar teks kontras di atas ilustrasi
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

          // 2. Konten Header Satpam
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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

                  // Sapaan Petugas dengan Capsule Pill Halus
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
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _guardHeader(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _stat('${all.length}', 'Total Laporan', kDeep),
                _stat('${wait.length}', 'Perlu Verifikasi', Colors.orange.shade800),
                _stat('${pend.length}', 'Klaim Menunggu', Colors.blue.shade800),
              ]),
              const SizedBox(height: 14),

              // Status Banner Pos Tugas
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: softC(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderC(context)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.shield, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Flexible(child: Text('Pos Tugas: ${store.guardPos}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        InkWell(
                          onTap: () => _switchPosModal(context),
                          child: Text('Ganti Pos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark(context) ? Colors.lightGreenAccent : kGreen)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text('Tunjukkan QR Barcode Pos di menu QR Pos saat pelapor/pengklaim datang.', style: TextStyle(fontSize: 11, color: mutedC(context), height: 1.3)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 18),

              // Antrean Verifikasi Laporan
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Antrean Verifikasi Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (wait.isNotEmpty) Text('${wait.length} antrean', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
              ]),
              Text('Laporan baru dari warga yang membutuhkan verifikasi fisik di pos.', style: TextStyle(fontSize: 11, color: mutedC(context))),
              const SizedBox(height: 10),
              if (wait.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded, color: kGreen, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Tidak Ada Laporan Menunggu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Semua laporan di ${store.guardPos} sudah terverifikasi.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                      ]),
                    ),
                  ]),
                )
              else
                for (final r in wait) ReportTile(r, () => openReport(context, r)),

              const SizedBox(height: 18),

              // Klaim Menunggu Verifikasi
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Klaim Menunggu Verifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (pend.isNotEmpty) Text('${pend.length} klaim', style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
              ]),
              Text('Klaim kepemilikan barang dari warga yang menunggu dicocokkan.', style: TextStyle(fontSize: 11, color: mutedC(context))),
              const SizedBox(height: 10),
              if (pend.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
                  child: Row(children: [
                    const Icon(Icons.assignment_turned_in_outlined, color: Colors.blue, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Tidak Ada Klaim Menunggu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Belum ada klaim barang baru yang perlu diproses.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                      ]),
                    ),
                  ]),
                )
              else
                for (final c in pend) ClaimTile(c, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimReviewScreen(c)))),

              if (verifiedAtPos.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text('Aktivitas Terakhir di Pos Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Laporan yang sudah diproses di ${store.guardPos}.', style: TextStyle(fontSize: 11, color: mutedC(context))),
                const SizedBox(height: 10),
                for (final r in verifiedAtPos) ReportTile(r, () => openReport(context, r)),
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
        final list = store.reports.where((r) => (f == 'Semua' || r.typeLabel == f || r.status == f) && (p == 'Semua Pos' || r.pos == p)).toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const BandHeader('Daftar Laporan'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FilterChips(const ['Semua', 'Hilang', 'Ditemukan', stWait, stClaimed, stDone], f, (v) => setState(() => f = v)),
                const SizedBox(height: 8),
                FilterChips(['Semua Pos', ...posList], p, (v) => setState(() => p = v)),
                const SizedBox(height: 14),
                for (final r in list) ReportTile(r, () => openReport(context, r)),
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

  @override
  void initState() {
    super.initState();
    _ensurePosToken();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (store.posTokenExp == null || DateTime.now().isAfter(store.posTokenExp!)) {
        store.issuePosToken(store.guardPos);
      }
      setState(() {});
    });
  }

  void _ensurePosToken() {
    if (store.posToken.isEmpty || store.posTokenExp == null || DateTime.now().isAfter(store.posTokenExp!)) {
      store.issuePosToken(store.guardPos);
    }
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
      _ensurePosToken();
      final left = (store.posTokenExp ?? DateTime.now()).difference(DateTime.now());
      final expired = left.isNegative || left.inSeconds <= 0;
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
          title: Text('QR Barcode Pos Satpam', style: TextStyle(fontSize: 16, color: textCol, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_on, color: dark ? Colors.amber : Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(store.guardPos, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                  border: Border.all(color: dark ? Colors.transparent : borderC(context)),
                ),
                child: QrImageView(data: payload, size: 180, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(code, textAlign: TextAlign.center, style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 6),
              Chip(
                avatar: const Icon(Icons.timer, size: 16, color: kDeep),
                backgroundColor: Colors.amber,
                label: Text(expired ? 'Kedaluwarsa' : 'Berlaku ${_mmss(left)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tunjukkan QR Barcode ini ke pelapor/pengklaim. QR akan BERGANTI OTOMATIS setelah 1 warga memindai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextCol, fontSize: 12, height: 1.3),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton('Perbarui QR Barcode Baru', () => store.issuePosToken(store.guardPos), outlined: true),
            ]),
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
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (r != null)
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 80, height: 80, child: ReportPhoto(r))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('${r.id}\n${r.pos}', style: TextStyle(fontSize: 11, color: mutedC(context))),
                  const SizedBox(height: 4),
                  StatusChip(c.status),
                ]),
              ),
            ]),
          const Divider(height: 26),
          InfoRow(Icons.person_outline, 'Pengklaim', c.claimer),
          InfoRow(Icons.tag, 'Kode Klaim', c.id),
          InfoRow(Icons.calendar_today_outlined, 'Diajukan', fmtDate(c.date)),
          const SizedBox(height: 6),
          const Text('Pencocokan Detail Rahasia', style: TextStyle(fontWeight: FontWeight.bold)),
          SecretBox('Detail rahasia pada laporan (pelapor & satpam)', r?.secret ?? '-'),
          SecretBox('Jawaban pengklaim', c.answer, color: Colors.orange.shade800),
          if (c.proof.isNotEmpty) InfoRow(Icons.description_outlined, 'Bukti tambahan', c.proof),
          if (c.photo != null && File(c.photo!).existsSync()) ...[
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(c.photo!), height: 180, width: double.infinity, fit: BoxFit.cover)),
          ],
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
        ]),
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
      Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
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
          const CircleAvatar(radius: 34, backgroundColor: kGreen, child: Icon(Icons.check, size: 38, color: Colors.white)),
          const SizedBox(height: 14),
          const Text('Serah Terima Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
            child: Column(children: [
              _row('Kode Klaim', c.id),
              _row('Barang', r?.name ?? '-'),
              _row('Penerima', c.claimer),
              _row('Waktu', fmtDate(DateTime.now())),
              _row('Petugas', '${store.name}\n${store.guardPos}'),
            ]),
          ),
          const Spacer(),
          PrimaryButton('Kembali ke Dashboard', () => Navigator.popUntil(context, (r) => r.isFirst)),
        ]),
      ),
    );
  }
}