import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'cartoon.dart';
import 'core.dart';
import 'guard_screens.dart';
import 'profile_screen.dart';
import 'sound.dart';
import 'widgets.dart';

/// Pelapor & satpam melihat detail lengkap (termasuk detail rahasia). Warga lain hanya detail publik.
Widget detailFor(Report r) => (store.guard || r.owner == store.email) ? FullDetailScreen(r) : PublicDetailScreen(r);
void openReport(BuildContext c, Report r) => Navigator.push(c, MaterialPageRoute(builder: (_) => detailFor(r)));

const _grid = SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .62);
String? requiredField(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

// ------------------------------------------------------------------ shell
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int tab = 0;
  String? _seen;

  @override
  void initState() {
    super.initState();
    _seen = store.lastNotif?.id;
    store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = store.unread(store.email);
      if (n > 0) _alert('Kamu punya $n notifikasi baru');
    });
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    final n = store.lastNotif;
    if (n != null && n.owner == store.email && n.id != _seen) {
      _seen = n.id;
      _alert(n.title);
    }
  }

  void _alert(String msg) {
    playAlert();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kDeep,
      content: Row(children: [
        const Icon(Icons.notifications_active, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      action: SnackBarAction(label: 'Lihat', textColor: Colors.amber, onPressed: () => setState(() => tab = 3)),
    ));
  }

  void go(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: tab, children: [
      StudentHome(onGo: go),
      const ReportHub(),
      const SearchScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ]),
    bottomNavigationBar: ListenableBuilder(
      listenable: store,
      builder: (context, _) => FloatingNav(
        index: tab,
        onTap: go,
        items: [
          const NavItem(Icons.home_outlined, Icons.home, 'Beranda'),
          const NavItem(Icons.assignment_outlined, Icons.assignment, 'Laporan'),
          const NavItem(Icons.search, Icons.search, 'Cari'),
          NavItem(Icons.notifications_none, Icons.notifications, 'Notifikasi', badge: store.unread(store.email)),
          const NavItem(Icons.person_outline, Icons.person, 'Profil'),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------- beranda
class StudentHome extends StatefulWidget {
  final void Function(int) onGo;
  const StudentHome({super.key, required this.onGo});
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String f = 'Semua';
  String selectedCat = 'Semua';

  Widget _header(BuildContext context) {
    final dark = isDark(context);
    final name = store.name.isEmpty ? 'Warga UNESA' : store.name;
    String? brandFont;
    try {
      brandFont = GoogleFonts.syne().fontFamily;
    } catch (_) {}

    return CartoonHeader(
      height: 320,
      bx: .5,
      bs: .52,
      groundY: .80,
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
                  ClipRRect(
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
                              'Halo, $name! ✨',
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categorySelector(BuildContext context) {
    final catList = ['Semua', ...categories];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: catList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = catList[index];
          final isSel = selectedCat == cat;
          return FilterChip(
            selected: isSel,
            showCheckmark: false,
            avatar: cat == 'Semua' ? null : Icon(catIcons[cat], size: 14, color: isSel ? Colors.white : kGreen),
            label: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.white : (isDark(context) ? Colors.white70 : Colors.black87),
              ),
            ),
            backgroundColor: cardC(context),
            selectedColor: kGreen,
            side: BorderSide(color: isSel ? kGreen : borderC(context)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (_) => setState(() => selectedCat = cat),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final pub = store.reports.where((r) => r.isPublic).toList()..sort((a, b) => b.date.compareTo(a.date));
      final list = pub.where((r) {
        final matchType = (f == 'Semua' || r.typeLabel == f);
        final matchCat = (selectedCat == 'Semua' || r.category == selectedCat || r.categoryLabel == selectedCat);
        return matchType && matchCat;
      }).toList();

      return CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _header(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Katalog Barang Terlapor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${list.length} item', style: TextStyle(fontSize: 12, color: mutedC(context), fontWeight: FontWeight.w600)),
              ]),
              Text('Barang hilang & ditemukan yang sudah diverifikasi satpam.', style: TextStyle(fontSize: 11, color: mutedC(context))),
              const SizedBox(height: 12),
              FilterChips(const ['Semua', 'Hilang', 'Ditemukan'], f, (v) => setState(() => f = v)),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: _categorySelector(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: mutedC(context).withValues(alpha: 0.5)),
                  const SizedBox(height: 10),
                  Text('Belum ada laporan barang', style: TextStyle(color: mutedC(context), fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverGrid(
              gridDelegate: _grid,
              delegate: SliverChildBuilderDelegate((c, i) => ItemCard(list[i], () => openReport(c, list[i])), childCount: list.length),
            ),
          ),
      ]);
    },
  );
}

// ------------------------------------------------- tab Laporan (hub)
class ReportHub extends StatefulWidget {
  const ReportHub({super.key});
  @override
  State<ReportHub> createState() => _ReportHubState();
}

class _ReportHubState extends State<ReportHub> {
  String tab = 'Laporan Saya';

  Widget _tile(BuildContext c, IconData icon, String title, String sub, Color tint, Color circle, Color iconColor, bool found) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ReportFormScreen(found: found))),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
        decoration: BoxDecoration(color: isDark(c) ? tint.withValues(alpha: .16) : tint, borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(radius: 28, backgroundColor: circle, child: Icon(icon, color: iconColor, size: 28)),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: mutedC(c))),
        ]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final mine = store.reports.where((r) => r.owner == store.email).toList();
      final myClaims = store.claims.where((c) => c.claimer == store.email).toList();
      return ListView(padding: EdgeInsets.zero, children: [
        const BandHeader('Laporan', subtitle: 'Laporkan barang hilang atau yang kamu temukan'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Buat Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _tile(context, Icons.description, 'Laporkan Barang Hilang', 'Barangku hilang', const Color(0xFFE6F0FF), const Color(0xFFCFE2FF), const Color(0xFF1F4E9C), false),
                const SizedBox(width: 12),
                _tile(context, Icons.inventory_2, 'Laporkan Barang Ditemukan', 'Aku menemukan barang', const Color(0xFFFFF3D4), const Color(0xFFFFD98A), const Color(0xFF8A5A12), true),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('Keterangan Laporan Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            FilterChips(const ['Laporan Saya', 'Klaim Saya'], tab, (v) => setState(() => tab = v)),
            const SizedBox(height: 12),
            if (tab == 'Laporan Saya') ...[
              if (mine.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Belum ada laporan.', style: TextStyle(color: mutedC(context))))),
              for (final r in mine) ReportTile(r, () => openReport(context, r)),
            ] else ...[
              if (myClaims.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Belum ada klaim.', style: TextStyle(color: mutedC(context))))),
              for (final c in myClaims)
                ClaimTile(c, () {
                  if (c.status == 'Menunggu') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => QrScreen(kind: 'C', targetId: c.id)));
                  } else {
                    final r = store.find(c.reportId);
                    if (r != null) openReport(context, r);
                  }
                }),
            ],
          ]),
        ),
      ]);
    },
  );
}

// -------------------------------------------------------- form laporan (buat & edit)
class ReportFormScreen extends StatefulWidget {
  final bool found;
  final Report? prefill;
  final Report? editing;
  const ReportFormScreen({super.key, required this.found, this.prefill, this.editing});
  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _form = GlobalKey<FormState>();
  final nameC = TextEditingController(), descC = TextEditingController(), secretC = TextEditingController(), detailC = TextEditingController(), catC = TextEditingController(), dateC = TextEditingController();
  String? category, area, pos, photo;
  DateTime date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      nameC.text = e.name;
      category = e.category;
      catC.text = e.categoryCustom;
      descC.text = e.description;
      secretC.text = e.secret;
      area = e.area;
      detailC.text = e.areaDetail;
      pos = e.pos;
      photo = e.photo;
      date = e.date;
      dateC.text = fmtDate(date);
      return;
    }
    dateC.text = fmtDate(date);
    final p = widget.prefill;
    if (p != null) {
      nameC.text = p.name;
      category = p.category;
      catC.text = p.categoryCustom;
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2024), lastDate: DateTime.now());
    if (d != null) {
      setState(() {
        date = d;
        dateC.text = fmtDate(d);
      });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final e = widget.editing;

    if (e != null) {
      final updated = Report(
        id: e.id,
        type: e.type,
        name: nameC.text.trim(),
        category: category!,
        categoryCustom: catC.text.trim(),
        description: descC.text.trim(),
        secret: secretC.text.trim(),
        area: area!,
        areaDetail: detailC.text.trim(),
        pos: pos!,
        owner: e.owner,
        date: date,
        photo: photo,
        status: e.status,
      );
      await store.updateReport(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan laporan berhasil disimpan!'), backgroundColor: kGreen),
      );
      Navigator.pop(context);
      return;
    }

    final r = Report(
      id: store.nextReportId(),
      type: widget.found ? ReportType.ditemukan : ReportType.hilang,
      name: nameC.text.trim(),
      category: category!,
      categoryCustom: catC.text.trim(),
      description: descC.text.trim(),
      secret: secretC.text.trim(),
      area: area!,
      areaDetail: detailC.text.trim(),
      pos: pos!,
      owner: store.email,
      date: date,
      photo: photo,
      status: stWait,
    );
    store.add(r);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubmittedScreen(
          title: 'Laporan Terkirim',
          message: 'Laporan "${r.name}" (${r.id}) menunggu verifikasi satpam di ${r.pos}. Tekan Lanjut untuk memindai QR Barcode Pos Satpam di pos. Setelah berhasil dipindai, laporan tampil di Beranda dan kamu mendapat notifikasi.',
          next: ScanGuardQrScreen(kind: 'R', targetId: r.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final found = widget.editing != null ? (widget.editing!.type == ReportType.ditemukan) : widget.found;
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Laporan (${widget.editing!.id})' : (found ? 'Lapor Barang Ditemukan' : 'Lapor Kehilangan'),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          AppField('Nama Barang', 'Contoh: Dompet hitam', controller: nameC, validator: requiredField),
          AppDropdown('Kategori Barang', 'Pilih kategori', categories, category, (v) => setState(() => category = v), isRequired: true),
          if (category == 'Lainnya') AppField('Tulis Kategori Barang', 'Contoh: Payung, botol minum, jaket', controller: catC, validator: requiredField),
          AppField('Deskripsi Umum (tampil ke publik)', 'Warna, merek, ukuran...', controller: descC, maxLines: 3, validator: requiredField),
          AppField(
            'Detail Rahasia',
            found ? 'Contoh: ada goresan di bagian dalam, gantungan bertuliskan nama' : 'Contoh: ada stiker coklat di bawah botol',
            controller: secretC,
            maxLines: 2,
            icon: Icons.lock_outline,
            helper: found
                ? 'Ciri tersembunyi yang kamu lihat. TIDAK tampil ke publik, hanya kamu dan satpam. Dipakai satpam mencocokkan dengan jawaban pengklaim.'
                : 'Ciri yang hanya pemilik tahu. TIDAK tampil ke publik, hanya kamu dan satpam. Mencegah orang sembarang mengklaim barangmu.',
            validator: requiredField,
          ),
          AppDropdown(found ? 'Lokasi Penemuan' : 'Lokasi Kehilangan', 'Pilih lokasi', areas, area, (v) => setState(() => area = v), isRequired: true),
          AppField('Detail Lokasi', 'Ketik manual, contoh: Gedung A3 lantai 2, dekat tangga', controller: detailC, validator: requiredField),
          AppField(found ? 'Tanggal Ditemukan' : 'Tanggal Hilang', 'Pilih tanggal', controller: dateC, icon: Icons.calendar_today_outlined, readOnly: true, onTap: _pickDate),
          AppDropdown('Pos Satpam', 'Pilih pos satpam', posList, pos, (v) => setState(() => pos = v),
              isRequired: true, helper: found ? 'Pos tempat barang diserahkan dan laporan diverifikasi.' : 'Pos tempat laporan diverifikasi dan tempat kamu mengecek barang temuan.'),
          const Text('Foto Barang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          PhotoBox(path: photo, onPicked: (p) => setState(() => photo = p)),
          const SizedBox(height: 20),
          PrimaryButton(isEdit ? 'Simpan Perubahan' : 'Kirim Laporan', _submit),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------- sukses & QR code
class SubmittedScreen extends StatelessWidget {
  final String title, message;
  final Widget next;
  const SubmittedScreen({super.key, required this.title, required this.message, required this.next});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          const Spacer(),
          const CircleAvatar(radius: 44, backgroundColor: kGreen, child: Icon(Icons.check, size: 52, color: Colors.white)),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: mutedC(context), height: 1.5)),
          const Spacer(),
          PrimaryButton('Lanjut', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next))),
        ]),
      ),
    ),
  );
}

/// Layar bagi warga (pelapor / pengklaim) untuk memindai QR Barcode Pos Satpam.
class ScanGuardQrScreen extends StatefulWidget {
  final String kind;
  final String targetId;
  const ScanGuardQrScreen({super.key, required this.kind, required this.targetId});
  @override
  State<ScanGuardQrScreen> createState() => _ScanGuardQrScreenState();
}

class _ScanGuardQrScreenState extends State<ScanGuardQrScreen> {
  bool busy = false;
  bool success = false;
  String successMsg = '';
  DateTime? _lastErrorSnack;
  late final MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _snack(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _handleScan(String raw) async {
    if (busy || success) return;
    setState(() => busy = true);

    try {
      final s = raw.trim();
      if (s.startsWith('CF|POS|')) {
        final parts = s.split('|');
        if (parts.length == 4) {
          final posName = parts[2].trim();
          final token = parts[3].trim();
          final err = await store.verifyByPosTokenAsync(widget.kind, widget.targetId, posName, token);
          if (!mounted) return;
          if (err != null) {
            final now = DateTime.now();
            if (_lastErrorSnack == null || now.difference(_lastErrorSnack!).inSeconds >= 3) {
              _lastErrorSnack = now;
              _snack(err);
            }
          } else {
            await controller.stop();
            playAlert();
            if (!mounted) return;
            setState(() {
              success = true;
              successMsg = widget.kind == 'R'
                  ? 'Laporanmu telah berhasil diverifikasi oleh Satpam di $posName dan resmi dipublikasikan!'
                  : 'Klaimmu telah berhasil diverifikasi oleh Satpam di $posName!';
            });
          }
        } else {
          _snack('Format QR Pos Satpam tidak valid.');
        }
      } else {
        _snack('QR tidak dikenali. Pindai QR Barcode yang ada pada HP Satpam.');
      }
    } finally {
      if (mounted && !success) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isR = widget.kind == 'R';
    final targetPos = isR
        ? (store.find(widget.targetId)?.pos ?? 'Pos Satpam')
        : (store.find(store.findClaim(widget.targetId)?.reportId ?? '')?.pos ?? 'Pos Satpam');
    final title = isR ? 'Pindai QR Satpam (Laporan)' : 'Pindai QR Satpam (Klaim)';
    final dark = isDark(context);
    final bgCol = dark ? kDeep : softC(context);
    final appBg = dark ? kDeep : cardC(context);
    final textCol = dark ? Colors.white : kDeep;
    final subTextCol = dark ? Colors.white70 : mutedC(context);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: appBg,
        foregroundColor: textCol,
        elevation: dark ? 0 : 1,
        title: Text(title, style: TextStyle(fontSize: 16, color: textCol, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: success
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const CircleAvatar(radius: 44, backgroundColor: kGreen, child: Icon(Icons.verified, size: 50, color: Colors.white)),
              const SizedBox(height: 20),
              Text('Verifikasi Berhasil!', textAlign: TextAlign.center, style: TextStyle(color: textCol, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(successMsg, textAlign: TextAlign.center, style: TextStyle(color: subTextCol, fontSize: 13, height: 1.4)),
              ),
              const Spacer(),
              PrimaryButton('Kembali ke Beranda', () => Navigator.popUntil(context, (r) => r.isFirst)),
            ],
          )
              : Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: [
                Text('Arahkan kamera ke QR Barcode yang tampil pada HP Satpam ($targetPos).',
                    textAlign: TextAlign.center, style: TextStyle(color: textCol, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Setelah berhasil memindai, laporanmu akan langsung terverifikasi!',
                    textAlign: TextAlign.center, style: TextStyle(color: subTextCol, fontSize: 11)),
              ]),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dark ? Colors.lightGreenAccent : kGreen, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: MobileScanner(
                  controller: controller,
                  errorBuilder: (c, e, w) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Izin kamera belum aktif atau kamera tidak tersedia di perangkat ini.',
                          textAlign: TextAlign.center, style: TextStyle(color: subTextCol)),
                    ),
                  ),
                  onDetect: (cap) {
                    final v = cap.barcodes.firstOrNull?.rawValue;
                    if (v != null) _handleScan(v);
                  },
                ),
              ),
            ),
            PrimaryButton('Batal / Kembali', () => Navigator.pop(context), outlined: true),
          ]),
        ),
      ),
    );
  }
}

typedef QrScreen = ScanGuardQrScreen;

// -------------------------------------------------------------- pencarian
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const days = ['Semua', 'Hari ini', '7 hari terakhir', '30 hari terakhir'];
  String q = '', day = 'Semua';
  String? cat, loc, type, pos;

  int get active => [day != 'Semua', cat != null, loc != null, type != null, pos != null].where((e) => e).length;

  bool _match(Report r) {
    if (!r.isPublic) return false;
    final s = q.toLowerCase().trim();
    if (s.isNotEmpty && !'${r.name} ${r.categoryLabel} ${r.area}'.toLowerCase().contains(s)) return false;
    final now = DateTime.now();
    final age = DateTime(now.year, now.month, now.day).difference(DateTime(r.date.year, r.date.month, r.date.day)).inDays;
    if (day == 'Hari ini' && age != 0) return false;
    if (day == '7 hari terakhir' && age > 7) return false;
    if (day == '30 hari terakhir' && age > 30) return false;
    if (cat != null && r.category != cat) return false;
    if (loc != null && r.area != loc) return false;
    if (type != null && r.typeLabel != type) return false;
    if (pos != null && r.pos != pos) return false;
    return true;
  }

  void _openFilter() {
    var d = day;
    String? c = cat, l = loc, t = type, p = pos;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Filter Pencarian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              AppDropdown('Hari', 'Semua', days, d, (v) => setS(() => d = v!)),
              AppDropdown('Kategori Barang (opsional)', 'Semua kategori', categories, c, (v) => setS(() => c = v)),
              AppDropdown('Lokasi (opsional)', 'Semua lokasi', areas, l, (v) => setS(() => l = v)),
              AppDropdown('Pos Satpam (opsional)', 'Semua pos', posList, p, (v) => setS(() => p = v)),
              AppDropdown('Jenis Laporan (opsional)', 'Hilang & Ditemukan', const ['Hilang', 'Ditemukan'], t, (v) => setS(() => t = v)),
              Row(children: [
                Expanded(
                  child: PrimaryButton('Reset', () => setS(() {
                    d = 'Semua';
                    c = l = t = p = null;
                  }), outlined: true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton('Terapkan', () {
                    setState(() {
                      day = d;
                      cat = c;
                      loc = l;
                      type = t;
                      pos = p;
                    });
                    Navigator.pop(ctx);
                  }),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, VoidCallback del) => Chip(label: Text(t, style: const TextStyle(fontSize: 11)), onDeleted: del, visualDensity: VisualDensity.compact);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.reports.where(_match).toList();
        return Column(children: [
          const BandHeader('Cari Barang', subtitle: 'Temukan barang dengan filter'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => q = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama barang, kategori, atau lokasi',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: cardC(context),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC(context))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: active > 0,
                  label: Text('$active'),
                  child: IconButton.filled(style: IconButton.styleFrom(backgroundColor: kGreen), onPressed: _openFilter, icon: const Icon(Icons.tune)),
                ),
              ]),
              if (active > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(spacing: 6, children: [
                      if (day != 'Semua') _chip(day, () => setState(() => day = 'Semua')),
                      if (cat != null) _chip(cat!, () => setState(() => cat = null)),
                      if (loc != null) _chip(loc!, () => setState(() => loc = null)),
                      if (pos != null) _chip(pos!, () => setState(() => pos = null)),
                      if (type != null) _chip(type!, () => setState(() => type = null)),
                    ]),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('Barang tidak ditemukan', style: TextStyle(color: mutedC(context))))
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              gridDelegate: _grid,
              itemCount: list.length,
              itemBuilder: (c, i) => ItemCard(list[i], () => openReport(c, list[i])),
            ),
          ),
        ]);
      },
    ),
  );
}

// -------------------------------------------- detail publik (rahasia tersembunyi)
class PublicDetailScreen extends StatelessWidget {
  final Report r;
  const PublicDetailScreen(this.r, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail Barang', style: TextStyle(fontSize: 16))),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final found = r.type == ReportType.ditemukan;
        final mine = store.pendingClaimOf(r.id, store.email);
        return ListView(padding: const EdgeInsets.all(16), children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 4 / 3, child: ReportPhoto(r))),
          const SizedBox(height: 14),
          Text(r.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [StatusChip(r.typeLabel), if (r.status != stActive) StatusChip(r.status)]),
          const Divider(height: 26),
          InfoRow(Icons.category_outlined, 'Kategori', r.categoryLabel),
          InfoRow(Icons.description_outlined, 'Deskripsi', r.description),
          InfoRow(Icons.place_outlined, 'Lokasi', r.area),
          InfoRow(Icons.calendar_today_outlined, 'Tanggal', fmtDate(r.date)),
          InfoRow(Icons.local_police_outlined, found ? 'Ambil / cek di' : 'Pos satpam', r.pos),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: softC(context), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lock_outline, size: 18, color: kGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Detail rahasia, lokasi rinci, dan data pelapor disembunyikan. Hanya pelapor dan satpam yang dapat melihatnya.',
                  style: TextStyle(fontSize: 12, color: mutedC(context), height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          if (r.status == stDone)
            Center(child: Text('Barang ini sudah diserahkan kepada pemiliknya.', style: TextStyle(color: mutedC(context))))
          else if (found && mine != null) ...[
            Text('Klaim kamu menunggu verifikasi satpam.', textAlign: TextAlign.center, style: TextStyle(color: mutedC(context))),
            const SizedBox(height: 10),
            PrimaryButton('Tampilkan QR Klaim', () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrScreen(kind: 'C', targetId: mine.id)))),
          ] else if (found)
            PrimaryButton('Ajukan Klaim', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimScreen(r))))
          else
            PrimaryButton('Saya Menemukan Barang Ini', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportFormScreen(found: true, prefill: r)))),
        ]);
      },
    ),
  );
}

// ------------------------------------------------------------------ klaim
class ClaimScreen extends StatefulWidget {
  final Report r;
  const ClaimScreen(this.r, {super.key});
  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _form = GlobalKey<FormState>();
  final answerC = TextEditingController(), proofC = TextEditingController();
  String? photo;

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final c = Claim(
      id: store.nextClaimId(),
      reportId: widget.r.id,
      claimer: store.email,
      answer: answerC.text.trim(),
      proof: proofC.text.trim(),
      photo: photo,
      date: DateTime.now(),
    );
    store.addClaim(c);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubmittedScreen(
          title: 'Klaim Terkirim',
          message: 'Tekan Lanjut untuk memindai QR Barcode Pos Satpam di ${widget.r.pos}. Satpam akan mencocokkan jawabanmu dengan detail rahasia pada laporan.',
          next: ScanGuardQrScreen(kind: 'C', targetId: c.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Klaim Kepemilikan', style: TextStyle(fontSize: 16))),
    body: Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.r.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Verifikasi oleh satpam di ${widget.r.pos}.', style: TextStyle(color: mutedC(context), fontSize: 12)),
        const SizedBox(height: 16),
        AppField(
          'Detail Rahasia Barang',
          'Sebutkan ciri tersembunyi yang hanya pemilik tahu',
          controller: answerC,
          maxLines: 3,
          icon: Icons.lock_outline,
          helper: 'Contoh: stiker di bagian bawah, isi di dalam, goresan khusus. Satpam akan mencocokkannya dengan laporan.',
          validator: requiredField,
        ),
        AppField('Bukti Tambahan (opsional)', 'Merek, nomor seri, kapan & di mana hilang', controller: proofC, maxLines: 2),
        const Text('Foto Pendukung (opsional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        PhotoBox(path: photo, onPicked: (p) => setState(() => photo = p)),
        const SizedBox(height: 20),
        PrimaryButton('Kirim Klaim', _submit),
      ]),
    ),
  );
}

// -------------------------------------- detail lengkap (pelapor & satpam)
class FullDetailScreen extends StatelessWidget {
  final Report r;
  final bool review;
  const FullDetailScreen(this.r, {super.key, this.review = false});

  Future<void> _confirmDelete(BuildContext context, Report report) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Laporan?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'Laporan "${report.name}" (${report.id}) yang belum diverifikasi akan dihapus permanen. Lanjutkan?',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await store.deleteReport(report.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dihapus.'), backgroundColor: Color(0xFFE11D48)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final current = store.find(r.id) ?? r;
      final isOwner = current.owner == store.email && !store.guard;
      final claims = store.claimsOf(current.id);

      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan', style: TextStyle(fontSize: 16))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 4 / 3, child: ReportPhoto(current))),
          const SizedBox(height: 14),
          Text(current.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [StatusChip(current.typeLabel), StatusChip(current.status)]),
          const Divider(height: 26),
          SecretBox('DETAIL RAHASIA (hanya pelapor & satpam)', current.secret),
          InfoRow(Icons.tag, 'Kode Laporan', current.id),
          InfoRow(Icons.category_outlined, 'Kategori', current.categoryLabel),
          InfoRow(Icons.description_outlined, 'Deskripsi', current.description),
          InfoRow(Icons.place_outlined, 'Lokasi', current.area),
          InfoRow(Icons.pin_drop_outlined, 'Detail Lokasi', current.areaDetail),
          InfoRow(Icons.calendar_today_outlined, 'Tanggal', fmtDate(current.date)),
          InfoRow(Icons.local_police_outlined, 'Pos Satpam', current.pos),
          InfoRow(Icons.person_outline, 'Pelapor', current.owner),
          if (claims.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Klaim pada barang ini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final c in claims)
              ClaimTile(c, () {
                if (store.guard) Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimReviewScreen(c)));
              }),
          ],
          const SizedBox(height: 18),
          if (isOwner && current.status == stWait) ...[
            PrimaryButton(
              'Pindai QR Pos Satpam untuk Verifikasi',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScanGuardQrScreen(kind: 'R', targetId: current.id))),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: kGreen, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportFormScreen(
                          found: current.type == ReportType.ditemukan,
                          editing: current,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18, color: kGreen),
                    label: const Text('Edit Laporan', style: TextStyle(fontWeight: FontWeight.w700, color: kGreen)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE11D48), width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _confirmDelete(context, current),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE11D48)),
                    label: const Text('Hapus Laporan', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE11D48))),
                  ),
                ),
              ],
            ),
          ],
          if (isOwner && current.type == ReportType.hilang && current.isPublic) ...[
            PrimaryButton('Barang Sudah Ketemu (Tutup Laporan)', () {
              store.complete(current);
              Navigator.pop(context);
            }),
          ],
          if (store.guard && current.status == stWait && !review)
            Text(
              'Untuk menyetujui, tunjukkan QR Barcode Pos Satpam di HP Anda untuk dipindai pelapor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: mutedC(context)),
            ),
          if (store.guard && review && current.status == stWait) ...[
            PrimaryButton('Setujui & Unggah Laporan', () {
              final m = ScaffoldMessenger.of(context);
              store.approveReport(current);
              Navigator.pop(context);
              m.showSnackBar(const SnackBar(content: Text('Laporan disetujui dan diunggah')));
            }),
            const SizedBox(height: 10),
            PrimaryButton('Tolak Laporan', () {
              final m = ScaffoldMessenger.of(context);
              store.rejectReport(current);
              Navigator.pop(context);
              m.showSnackBar(const SnackBar(content: Text('Laporan ditolak')));
            }, outlined: true),
          ],
        ]),
      );
    },
  );
}

// ------------------------------------------------------------ notifikasi
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String f = 'Semua';

  (IconData, Color) _style(String t) => switch (t) {
    'match' => (Icons.auto_awesome, Colors.amber.shade800),
    'verified' => (Icons.verified, kGreen),
    'claim' => (Icons.how_to_reg, Colors.blue),
    _ => (Icons.info_outline, Colors.blueGrey),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.notifs.where((n) => n.owner == store.email).toList();
        final list = all.where((n) => f == 'Semua' || !n.read).toList();
        return ListView(padding: EdgeInsets.zero, children: [
          BandHeader(
            'Notifikasi',
            subtitle: 'Info kecocokan & status verifikasi',
            trailing: TextButton(
              onPressed: () => store.markAllRead(store.email),
              child: const Text('Tandai dibaca', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FilterChips(const ['Semua', 'Belum dibaca'], f, (v) => setState(() => f = v)),
              const SizedBox(height: 12),
              if (list.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Belum ada notifikasi', style: TextStyle(color: mutedC(context))))),
              for (final n in list)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: n.read ? cardC(context) : softC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: _style(n.type).$2.withValues(alpha: .15), child: Icon(_style(n.type).$1, color: _style(n.type).$2)),
                    title: Row(children: [
                      Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      if (!n.read) const CircleAvatar(radius: 4, backgroundColor: Colors.red),
                    ]),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 2),
                      Text(n.message, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(ago(n.time), style: TextStyle(fontSize: 10, color: mutedC(context))),
                    ]),
                    onTap: () {
                      store.markRead(n);
                      if (n.type == 'match' && n.matchIds.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MatchScreen(n)));
                      } else if (n.reportId != null) {
                        final r = store.find(n.reportId!);
                        if (r != null) openReport(context, r);
                      }
                    },
                  ),
                ),
            ]),
          ),
        ]);
      },
    ),
  );
}

class MatchScreen extends StatelessWidget {
  final AppNotif n;
  const MatchScreen(this.n, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kecocokan Barang', style: TextStyle(fontSize: 16))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: softC(context), borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_awesome, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dicocokkan otomatis dari nama, kategori, deskripsi, lokasi, dan tanggal. Pemilik asli tetap diverifikasi satpam lewat detail rahasia.',
              style: TextStyle(fontSize: 12, color: mutedC(context), height: 1.4),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      for (var i = 0; i < n.matchIds.length; i++) ...[
        Builder(builder: (context) {
          final r = store.find(n.matchIds[i]);
          if (r == null) return const SizedBox();
          final s = i < n.scores.length ? n.scores[i] : 0.0;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openReport(context, r),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cardC(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC(context))),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 76, height: 76, child: ReportPhoto(r))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${r.area}\n${r.pos}', style: TextStyle(fontSize: 11, color: mutedC(context))),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: s, minHeight: 8, color: kGreen, backgroundColor: borderC(context)),
                    ),
                    const SizedBox(height: 4),
                    Text('Kecocokan ${(s * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kGreen)),
                  ]),
                ),
              ]),
            ),
          );
        }),
      ],
    ]),
  );
}