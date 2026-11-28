import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'api_keys.dart';
import 'cartoon.dart';
import 'core.dart';
import 'guard_screens.dart';
import 'profile_screen.dart';
import 'sound.dart';
import 'widgets.dart';

/// Pelapor & satpam melihat detail lengkap. Mahasiswa lain hanya detail publik.
Widget detailFor(Report r) => (store.guard || r.owner == store.email)
    ? FullDetailScreen(r)
    : PublicDetailScreen(r);
void openReport(BuildContext c, Report r) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => detailFor(r)));

const _grid = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: .66,
);
String? requiredField(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

Widget _sheetPage(
    BuildContext context, {
      required Widget header,
      required double headerHeight,
      required Widget body,
      EdgeInsetsGeometry? padding,
    }) {
  final dark = isDark(context);
  final bgColor = dark ? const Color(0xFF09111E) : const Color(0xFFF1F5F9);

  return Container(
    color: bgColor,
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Stack(
        children: [
          header,
          Container(
            margin: EdgeInsets.only(top: headerHeight - 24),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight:
              MediaQuery.sizeOf(context).height - (headerHeight - 24),
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: body,
          ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------------ shell (4 Tab Navbar Gelombang Tetap)
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
      backgroundColor: kNavyPrimary,
      content: Row(children: [
        const Icon(Icons.notifications_active, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      action: SnackBarAction(
          label: 'Lihat',
          textColor: const Color(0xFF38BDF8),
          onPressed: () => setState(() => tab = 2)),
    ));
  }

  void go(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: tab == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      if (tab != 0) setState(() => tab = 0);
    },
    child: Scaffold(
      extendBody: true,
      body: IndexedStack(index: tab, children: [
        TickerMode(enabled: tab == 0, child: StudentHome(onGo: go)),
        TickerMode(enabled: tab == 1, child: const ReportHub()),
        TickerMode(enabled: tab == 2, child: const NotificationsScreen()),
        TickerMode(enabled: tab == 3, child: const ProfileScreen()),
      ]),
      bottomNavigationBar: ListenableBuilder(
        listenable: store,
        builder: (context, _) => FloatingNav(
          index: tab,
          onTap: go,
          items: [
            const NavItem(Icons.home_outlined, Icons.home, 'Beranda'),
            const NavItem(
                Icons.assignment_outlined, Icons.assignment, 'Laporan'),
            NavItem(Icons.notifications_none, Icons.notifications,
                'Notifikasi',
                badge: store.unread(store.email)),
            const NavItem(Icons.person_outline, Icons.person, 'Profil'),
          ],
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------- beranda bersih (Gedung Tetap di Atas)
class StudentHome extends StatefulWidget {
  final void Function(int) onGo;
  const StudentHome({super.key, required this.onGo});
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  static const _days = [
    'Semua',
    'Hari ini',
    '7 hari terakhir',
    '30 hari terakhir'
  ];

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _day = 'Semua';
  String? _cat;
  String? _type;
  String? _pos;

  int get _activeFilterCount => [
    _day != 'Semua',
    _cat != null,
    _type != null,
    _pos != null,
  ].where((e) => e).length;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _match(Report r) {
    if (!r.isPublic) return false;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = '${r.name} ${r.categoryLabel} ${r.pos} ${r.description}'
          .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    final now = DateTime.now();
    final age = DateTime(now.year, now.month, now.day)
        .difference(DateTime(r.date.year, r.date.month, r.date.day))
        .inDays;
    if (_day == 'Hari ini' && age != 0) return false;
    if (_day == '7 hari terakhir' && age > 7) return false;
    if (_day == '30 hari terakhir' && age > 30) return false;
    if (_cat != null && r.category != _cat) return false;
    if (_type != null && r.typeLabel != _type) return false;
    if (_pos != null && r.pos != _pos) return false;
    return true;
  }

  void _openFilterSheet() {
    var d = _day;
    String? c = _cat, t = _type, p = _pos;
    final availablePos = store.availablePosList;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeading(ctx, 'Filter Barang'),
                const SizedBox(height: 14),
                AppDropdown('Jenis Laporan', 'Semua (Hilang & Ditemukan)',
                    const ['Hilang', 'Ditemukan'], t, (v) => setS(() => t = v)),
                AppDropdown('Kategori Barang', 'Semua kategori', categories, c,
                        (v) => setS(() => c = v)),
                AppDropdown('Pos Satpam', 'Semua pos', availablePos, p,
                        (v) => setS(() => p = v)),
                AppDropdown('Waktu', 'Semua waktu', _days, d,
                        (v) => setS(() => d = v ?? 'Semua')),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        'Reset',
                            () => setS(() {
                          d = 'Semua';
                          c = t = p = null;
                        }),
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        'Terapkan',
                            () {
                          setState(() {
                            _day = d;
                            _cat = c;
                            _type = t;
                            _pos = p;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPosInfoSheet(BuildContext context) {
    final dark = isDark(context);
    final availablePos = store.availablePosList;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: store,
        builder: (ctx, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionHeading(ctx, 'Layanan Pos Satpam UNESA'),
              const SizedBox(height: 12),
              const HomeHoursCard(),
              const SizedBox(height: 14),
              Text(
                'Titik Pos & Petugas Bertugas Saat Ini:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : kSlateHeading,
                ),
              ),
              const SizedBox(height: 8),
              for (final posName in availablePos)
                Builder(builder: (context) {
                  final officer = store.activeOfficerForPos(posName);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 16,
                            color: dark ? const Color(0xFF38BDF8) : kToska),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(posName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                officer != null
                                    ? 'Petugas saat ini: ${officer.name} (${officer.shift})'
                                    : 'Belum ada jadwal petugas aktif',
                                style: TextStyle(
                                    fontSize: 11.5, color: mutedC(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final dark = isDark(context);
      final name = store.name.isEmpty ? 'Mahasiswa UNESA' : store.name;
      final filtered = store.reports.where(_match).toList();
      final hasFilter = _query.trim().isNotEmpty || _activeFilterCount > 0;
      final toskaAccent = dark ? const Color(0xFF22B8CF) : kToska;

      return _sheetPage(
        context,
        headerHeight: 280,
        header: HomeHeader(
          name: name,
          height: 280,
          onProfile: () => widget.onGo(3),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kolom Pencarian + Tombol Filter
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardC(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderC(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: dark ? 0.20 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Cari dompet, kunci, KTM, tumbler...',
                        hintStyle:
                        TextStyle(color: mutedC(context), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: toskaAccent, size: 22),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 19),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: _activeFilterCount > 0,
                  label: Text('$_activeFilterCount'),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filled(
                      tooltip: 'Filter Barang',
                      style: IconButton.styleFrom(
                        backgroundColor:
                        dark ? const Color(0xFF0E7490) : kToska,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _openFilterSheet,
                      icon: const Icon(Icons.tune_rounded,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Banner Ajakan "Lapor Sekarang"
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF132F3B) : kMintSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF22B8CF).withValues(alpha: 0.30)
                      : kToska.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lapor barang hilang atau ditemukan dengan mudah!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : kNavyPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 34,
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onGo(1),
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 16),
                            label: const Text(
                              'Lapor Sekarang',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              dark ? const Color(0xFF0E7490) : kToska,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF0E7490).withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 28,
                      color: toskaAccent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. Status Layanan Pos Satpam
            HomePosStatusPill(onTap: () => _showPosInfoSheet(context)),

            const SizedBox(height: 18),

            // 4. Grid Barang Terbaru
            Row(
              children: [
                Expanded(
                  child: sectionHeading(
                    context,
                    hasFilter ? 'Hasil Pencarian' : 'Barang Terbaru',
                    trailing: '${filtered.length} barang',
                  ),
                ),
                if (_activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _day = 'Semua';
                      _cat = _type = _pos = null;
                    }),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: toskaAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 36, horizontal: 20),
                decoration:
                emeraldGlassDecoration(context, elevated: false),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 38, color: mutedC(context)),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada barang yang sesuai',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: dark ? Colors.white : kSlateHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coba ubah kata kunci pencarian atau reset filter.',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 12, color: mutedC(context)),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: _grid,
                itemCount: filtered.length,
                itemBuilder: (c, i) =>
                    ItemCard(filtered[i], () => openReport(c, filtered[i])),
              ),
          ],
        ),
      );
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

  Widget _actionCard(
      BuildContext c, {
        required IconData icon,
        required String title,
        required String sub,
        required Color accent,
        required bool found,
      }) {
    final dark = isDark(c);
    return Expanded(
      child: TapScale(
        onTap: () => Navigator.push(c,
            MaterialPageRoute(builder: (_) => ReportFormScreen(found: found))),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardC(c),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderC(c)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: dark ? Colors.white : kSlateHeading,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                style:
                TextStyle(fontSize: 11.5, color: mutedC(c), height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final mine =
      store.reports.where((r) => r.owner == store.email).toList();
      final myClaims =
      store.claims.where((c) => c.claimer == store.email).toList();
      final dark = isDark(context);

      return _sheetPage(
        context,
        headerHeight: 144,
        header: const BandHeader('Laporan',
            subtitle: 'Laporkan barang hilang atau yang kamu temukan'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeading(context, 'Buat Laporan Baru'),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _actionCard(
                    context,
                    icon: Icons.search_off_rounded,
                    title: 'Barang Hilang',
                    sub: 'Laporkan barangmu yang tercecer',
                    accent: const Color(0xFFDC2626),
                    found: false,
                  ),
                  const SizedBox(width: 12),
                  _actionCard(
                    context,
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Barang Temuan',
                    sub: 'Serahkan temuan ke pos satpam',
                    accent: dark ? const Color(0xFF22B8CF) : kToska,
                    found: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            sectionHeading(context, 'Riwayat Aktivitas'),
            const SizedBox(height: 10),
            FilterChips(const ['Laporan Saya', 'Klaim Saya'], tab,
                    (v) => setState(() => tab = v)),
            const SizedBox(height: 12),
            if (tab == 'Laporan Saya') ...[
              if (mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                      child: Text('Belum ada laporan yang dibuat.',
                          style: TextStyle(color: mutedC(context)))),
                ),
              for (final r in mine)
                ReportTile(r, () => openReport(context, r)),
            ] else ...[
              if (myClaims.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                      child: Text('Belum ada pengajuan klaim.',
                          style: TextStyle(color: mutedC(context)))),
                ),
              for (final c in myClaims)
                ClaimTile(c, () {
                  if (c.status == 'Menunggu') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                QrScreen(kind: 'C', targetId: c.id)));
                  } else {
                    final r = store.find(c.reportId);
                    if (r != null) openReport(context, r);
                  }
                }),
            ],
          ],
        ),
      );
    },
  );
}

// -------------------------------------------------------- form laporan (buat & edit)
class ReportFormScreen extends StatefulWidget {
  final bool found;
  final Report? prefill;
  final Report? editing;
  const ReportFormScreen(
      {super.key, required this.found, this.prefill, this.editing});
  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _form = GlobalKey<FormState>();
  final nameC = TextEditingController(),
      descC = TextEditingController(),
      catC = TextEditingController(),
      dateC = TextEditingController();
  String? category, pos, photo;
  DateTime date = DateTime.now();
  final jenisC = TextEditingController(),
      warnaC = TextEditingController(),
      ciriC = TextEditingController();
  bool _aiLoading = false;
  bool _aiDetected = false;
  bool _aiFailed = false;

  static const String _geminiKey = geminiApiKey;

  String _formatDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${fmtDate(dt)} • $hh:$mm WIB';
  }

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      nameC.text = e.name;
      category = e.category;
      catC.text = e.categoryCustom;
      descC.text = e.description;
      _parseDesc(e.description);
      pos = e.pos;
      photo = e.photo;
      date = e.date;
      dateC.text = _formatDateTime(date);
      _aiDetected = true;
      return;
    }

    dateC.text = _formatDateTime(date);
    final p = widget.prefill;
    if (p != null) {
      nameC.text = p.name;
      category = p.category;
      catC.text = p.categoryCustom;
      _aiDetected = true;
    }
  }

  Future<void> _pickLostDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (!mounted) return;

    setState(() {
      date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? date.hour,
        pickedTime?.minute ?? date.minute,
      );
      dateC.text = _formatDateTime(date);
    });
  }

  void _parseDesc(String d) {
    final m = RegExp(
      r'^(?:Jenis:\s*(.*?))?(?:,?\s*Warna:\s*(.*?))?(?:,?\s*Ciri-ciri:\s*(.*))?$',
      dotAll: true,
    ).firstMatch(d.trim());
    if (m == null) {
      ciriC.text = d;
      return;
    }
    jenisC.text = (m.group(1) ?? '').trim();
    warnaC.text = (m.group(2) ?? '').trim();
    ciriC.text = (m.group(3) ?? '').trim();
  }

  String _composeDesc() {
    final parts = <String>[];
    if (jenisC.text.trim().isNotEmpty) {
      parts.add('Jenis: ${jenisC.text.trim()}');
    }
    if (warnaC.text.trim().isNotEmpty) {
      parts.add('Warna: ${warnaC.text.trim()}');
    }
    if (ciriC.text.trim().isNotEmpty) {
      parts.add('Ciri-ciri: ${ciriC.text.trim()}');
    }
    return parts.join(', ');
  }

  String _detectMime(Uint8List b) {
    if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E) {
      return 'image/png';
    }
    if (b.length > 11 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[8] == 0x57) return 'image/webp';
    return 'image/jpeg';
  }

  void _aiSnack(String msg, {Color color = Colors.orange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _analyzePhotoWithAi(String photoPath) async {
    if (photoPath.isEmpty) return;
    setState(() => _aiLoading = true);

    try {
      Uint8List imageBytes;
      if (photoPath.startsWith('data:image')) {
        imageBytes = base64Decode(photoPath.split(',').last);
      } else if (!kIsWeb) {
        final file = File(photoPath);
        if (!file.existsSync()) return;
        imageBytes = await file.readAsBytes();
      } else {
        return;
      }

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                'Analisis foto barang ini. Kembalikan HANYA JSON murni tanpa markdown/backticks, dengan tepat 5 key:\n'
                    '{\n'
                    '  "nama_barang": "nama spesifik barang (singkat)",\n'
                    '  "kategori": "salah satu dari: Dompet, Elektronik, Tas, Kunci, Pakaian, Dokumen/Kartu, Alat Tulis, Lainnya",\n'
                    '  "jenis_barang": "jenis/tipe barang, contoh: Boneka plushie, Dompet kulit, Smartphone",\n'
                    '  "warna": "warna dominan barang",\n'
                    '  "ciri_ciri": "ciri khas yang terlihat: motif, merek, goresan, stiker, kondisi, aksesoris. Isi - jika tidak ada"\n'
                    '}'
              },
              {
                'inline_data': {
                  'mime_type': _detectMime(imageBytes),
                  'data': base64Encode(imageBytes),
                }
              }
            ]
          }
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      });

      const models = [
        'gemini-3.5-flash',
        'gemini-3.6-flash',
        'gemini-3.5-flash-lite',
        'gemini-3.1-flash-lite'
      ];
      int lastStatus = 0;

      for (final modelName in models) {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent');

        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final res = await http
                .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _geminiKey,
              },
              body: requestBody,
            )
                .timeout(const Duration(seconds: 25));

            lastStatus = res.statusCode;

            if (res.statusCode == 200) {
              final resJson = jsonDecode(res.body) as Map<String, dynamic>;
              final candidates = resJson['candidates'] as List?;
              final content = (candidates != null && candidates.isNotEmpty)
                  ? (candidates[0] as Map<String, dynamic>)['content']
              as Map<String, dynamic>?
                  : null;
              final parts = content?['parts'] as List?;
              final text = (parts != null && parts.isNotEmpty)
                  ? ((parts[0]['text'] as String?) ?? '')
                  : '';

              final start = text.indexOf('{');
              final end = text.lastIndexOf('}');
              if (start == -1 || end <= start) break;

              final data = jsonDecode(text.substring(start, end + 1))
              as Map<String, dynamic>;
              final aiName = (data['nama_barang'] as String?)?.trim() ?? '';
              final aiCategory = (data['kategori'] as String?)?.trim() ?? '';
              final aiJenis = (data['jenis_barang'] as String?)?.trim() ?? '';
              final aiWarna = (data['warna'] as String?)?.trim() ?? '';
              var aiCiri = (data['ciri_ciri'] as String?)?.trim() ?? '';
              if (aiCiri == '-') aiCiri = '';

              if (!mounted) return;
              setState(() {
                if (aiName.isNotEmpty) nameC.text = aiName;
                jenisC.text = aiJenis;
                warnaC.text = aiWarna;
                ciriC.text = aiCiri;
                descC.text = _composeDesc();
                if (aiCategory.isNotEmpty) {
                  category = categories.firstWhere(
                        (c) =>
                    c.toLowerCase() == aiCategory.toLowerCase() ||
                        c.toLowerCase().contains(aiCategory.toLowerCase()) ||
                        aiCategory.toLowerCase().contains(c.toLowerCase()),
                    orElse: () => 'Lainnya',
                  );
                }
                _aiDetected = true;
              });
              _aiSnack('✨ AI berhasil mengenali barang dari foto!',
                  color: kToska);
              return;
            }

            if (res.statusCode == 429 ||
                res.statusCode == 503 ||
                res.statusCode == 500) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            break;
          } on TimeoutException {
            lastStatus = 0;
            break;
          } on SocketException {
            lastStatus = -1;
            break;
          } catch (e) {
            lastStatus = 0;
            break;
          }
        }

        if (lastStatus == 400 ||
            lastStatus == 401 ||
            lastStatus == 403 ||
            lastStatus == -1) break;
      }

      if (lastStatus == 400 || lastStatus == 401 || lastStatus == 403) {
        _aiSnack('API key AI tidak valid / belum diizinkan (kode $lastStatus).',
            color: Colors.red);
      } else if (lastStatus == -1) {
        _aiSnack(
            'Tidak ada koneksi internet. Periksa jaringan lalu tekan Generate Ulang AI.');
      } else {
        _aiSnack(
            'Server AI sedang sibuk ($lastStatus), silakan tekan Generate Ulang AI.');
      }
    } catch (e) {
      _aiSnack('Server AI sedang sibuk, silakan tekan Generate Ulang AI.');
    } finally {
      if (mounted) {
        setState(() {
          _aiLoading = false;
          if (!_aiDetected) _aiFailed = true;
        });
      }
    }
  }

  Future<void> _submit() async {
    final isFound = widget.editing != null
        ? (widget.editing!.type == ReportType.ditemukan)
        : widget.found;

    if (isFound && (photo == null || photo!.isEmpty)) {
      _aiSnack('Unggah foto barang terlebih dahulu.');
      return;
    }
    if (!_form.currentState!.validate()) return;

    final finalName = nameC.text.trim().isEmpty
        ? (isFound ? 'Barang Ditemukan' : 'Barang Hilang')
        : nameC.text.trim();
    final finalCategory = category ?? 'Lainnya';
    descC.text = _composeDesc();
    final finalDesc = descC.text.trim().isEmpty
        ? (isFound
        ? 'Dilaporkan melalui foto barang'
        : 'Dilaporkan kehilangan barang')
        : descC.text.trim();
    final e = widget.editing;

    if (e != null) {
      final updated = Report(
        id: e.id,
        type: e.type,
        name: finalName,
        category: finalCategory,
        categoryCustom: catC.text.trim(),
        description: finalDesc,
        secret: '',
        area: pos!,
        areaDetail: '',
        pos: pos!,
        owner: e.owner,
        date: date,
        photo: photo,
        status: e.status,
      );
      await store.updateReport(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perubahan laporan berhasil disimpan!'),
            backgroundColor: kToska),
      );
      Navigator.pop(context);
      return;
    }

    final r = Report(
      id: store.nextReportId(),
      type: isFound ? ReportType.ditemukan : ReportType.hilang,
      name: finalName,
      category: finalCategory,
      categoryCustom: catC.text.trim(),
      description: finalDesc,
      secret: '',
      area: pos!,
      areaDetail: '',
      pos: pos!,
      owner: store.email,
      date: date,
      photo: photo,
      status: stWait,
    );
    store.add(r);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kToska,
        duration: const Duration(seconds: 5),
        content: Text(
          'Laporan "${r.name}" tersimpan! Kamu bisa scan QR di ${r.pos} kapan saja lewat tab Laporan.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final found = widget.editing != null
        ? (widget.editing!.type == ReportType.ditemukan)
        : widget.found;
    final isEdit = widget.editing != null;
    final dark = isDark(context);
    final toskaAccent = dark ? const Color(0xFF22B8CF) : kToska;

    // Penemu wajib unggah foto dulu; pelapor kehilangan langsung lihat form (foto opsional)
    final showFields = !found || ((_aiDetected || _aiFailed) && !_aiLoading);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Edit Laporan (${widget.editing!.id})'
              : (found ? 'Lapor Barang Ditemukan' : 'Lapor Kehilangan'),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final availablePos = store.availablePosList;
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                sectionHeading(
                    context, found ? 'Foto Barang' : 'Foto Barang (Opsional)'),
                if (!found) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unggah foto jika kamu memiliki fotonya (AI akan membantu mengisi detail otomatis).',
                    style: TextStyle(fontSize: 12, color: mutedC(context)),
                  ),
                ],
                const SizedBox(height: 8),
                PhotoBox(
                  path: photo,
                  onPicked: (p) {
                    setState(() {
                      photo = p;
                      _aiDetected = false;
                      _aiFailed = false;
                    });
                    if (p != null && p.isNotEmpty) {
                      _analyzePhotoWithAi(p);
                    }
                  },
                ),
                if (_aiLoading) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: toskaAccent.withValues(alpha: dark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                      Border.all(color: toskaAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: toskaAccent),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI sedang mengenali barang...',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: toskaAccent),
                        ),
                      ],
                    ),
                  ),
                ],
                if (photo != null && photo!.isNotEmpty && !_aiLoading) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _analyzePhotoWithAi(photo!),
                      icon: Icon(Icons.auto_awesome_rounded,
                          size: 16, color: toskaAccent),
                      label: Text(
                        '✨ Generate Ulang AI',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: toskaAccent,
                        ),
                      ),
                    ),
                  ),
                ],
                if (showFields && !_aiLoading) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                          _aiDetected
                              ? Icons.auto_awesome_rounded
                              : Icons.edit_note_rounded,
                          size: 18,
                          color: toskaAccent),
                      const SizedBox(width: 6),
                      Text(
                        _aiDetected ? 'Hasil Analisis AI' : 'Detail Barang',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _aiDetected
                        ? 'Periksa dan ubah jika ada yang kurang tepat.'
                        : (found
                        ? 'AI belum berhasil, silakan isi detail barang secara manual.'
                        : 'Deskripsikan barangmu sedetail mungkin agar mudah dikenali.'),
                    style: TextStyle(fontSize: 12, color: mutedC(context)),
                  ),
                  const SizedBox(height: 10),
                  AppField(
                    'Nama Barang',
                    'Contoh: Boneka Harimau Kuning',
                    controller: nameC,
                    icon: Icons.inventory_2_outlined,
                    validator: found ? null : requiredField,
                  ),
                  AppField(
                    'Jenis Barang',
                    'Contoh: Boneka plushie',
                    controller: jenisC,
                    icon: Icons.category_outlined,
                    validator: found ? null : requiredField,
                  ),
                  AppField(
                    'Warna',
                    'Contoh: Kuning dan putih',
                    controller: warnaC,
                    icon: Icons.palette_outlined,
                    validator: found ? null : requiredField,
                  ),
                  AppField(
                    'Ciri-ciri',
                    found
                        ? 'Contoh: ada garis hitam, pipi merah muda'
                        : 'Sebutkan merek, stiker, goresan, atau kelengkapan barang',
                    controller: ciriC,
                    maxLines: 3,
                    icon: Icons.fingerprint,
                    validator: found ? null : requiredField,
                  ),
                  AppDropdown(
                      'Kategori',
                      'Pilih kategori',
                      categories,
                      categories.contains(category) ? category : null,
                          (v) => setState(() => category = v)),
                  if (!found) ...[
                    const SizedBox(height: 16),
                    AppField(
                      'Kapan Terakhir Hilang',
                      'Pilih tanggal & perkiraan jam terakhir terlihat',
                      controller: dateC,
                      readOnly: true,
                      icon: Icons.event_available_outlined,
                      suffix: Icon(Icons.calendar_month_rounded,
                          color: toskaAccent),
                      onTap: _pickLostDateTime,
                      validator: requiredField,
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppDropdown(
                      'Pos Satpam',
                      'Pilih pos satpam',
                      availablePos,
                      availablePos.contains(pos) ? pos : null,
                          (v) => setState(() => pos = v),
                      isRequired: true),
                  if (pos != null) ...[
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final officer = store.activeOfficerForPos(pos!);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                          toskaAccent.withValues(alpha: dark ? 0.14 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: toskaAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user_rounded,
                                size: 20, color: toskaAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                officer != null
                                    ? 'Petugas berjaga saat ini: ${officer.name} (${officer.shift}). Silakan lakukan verifikasi QR di $pos.'
                                    : 'Pos $pos siap melayani verifikasi laporan.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: dark ? Colors.white : kNavyPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                      isEdit ? 'Simpan Perubahan' : 'Kirim Laporan', _submit),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------- sukses & QR code
class SubmittedScreen extends StatelessWidget {
  final String title, message;
  final Widget next;
  const SubmittedScreen(
      {super.key,
        required this.title,
        required this.message,
        required this.next});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          const Spacer(),
          const CircleAvatar(
              radius: 44,
              backgroundColor: kToska,
              child: Icon(Icons.check, size: 52, color: Colors.white)),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedC(context), height: 1.5)),
          const Spacer(),
          PrimaryButton(
              'Lanjut',
                  () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => next))),
        ]),
      ),
    ),
  );
}

class ScanGuardQrScreen extends StatefulWidget {
  final String kind;
  final String targetId;
  const ScanGuardQrScreen(
      {super.key, required this.kind, required this.targetId});
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
          final err = await store.verifyByPosTokenAsync(
              widget.kind, widget.targetId, posName, token);
          if (!mounted) return;
          if (err != null) {
            final now = DateTime.now();
            if (_lastErrorSnack == null ||
                now.difference(_lastErrorSnack!).inSeconds >= 3) {
              _lastErrorSnack = now;
              _snack(err);
            }
          } else {
            await controller.stop();
            playAlert();
            if (!mounted) return;
            final officer = store.activeOfficerForPos(posName);
            final officerLabel =
            officer != null ? officer.name : 'Petugas Satpam';
            setState(() {
              success = true;
              successMsg = widget.kind == 'R'
                  ? 'Laporanmu telah berhasil diverifikasi oleh $officerLabel di $posName dan resmi dipublikasikan!'
                  : 'Klaimmu telah berhasil diverifikasi oleh $officerLabel di $posName!';
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
        : (store.find(store.findClaim(widget.targetId)?.reportId ?? '')?.pos ??
        'Pos Satpam');
    final title =
    isR ? 'Pindai QR Verifikasi' : 'Pindai QR Verifikasi Klaim';
    final dark = isDark(context);
    final bgCol = dark ? const Color(0xFF09111E) : const Color(0xFFF1F5F9);
    final appBg = dark ? const Color(0xFF111D30) : Colors.white;
    final textCol = dark ? Colors.white : kSlateHeading;
    final subTextCol = dark ? Colors.white70 : mutedC(context);
    final borderCol = dark ? const Color(0xFF22B8CF) : kToska;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: appBg,
        foregroundColor: textCol,
        elevation: 0,
        title: Text(title,
            style: TextStyle(
                fontSize: 16, color: textCol, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: success
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const CircleAvatar(
                  radius: 44,
                  backgroundColor: kToska,
                  child: Icon(Icons.verified,
                      size: 50, color: Colors.white)),
              const SizedBox(height: 20),
              Text('Verifikasi Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: textCol,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(successMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: subTextCol, fontSize: 13, height: 1.4)),
              ),
              const Spacer(),
              PrimaryButton(
                  'Kembali ke Beranda',
                      () =>
                      Navigator.popUntil(context, (r) => r.isFirst)),
            ],
          )
              : Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Column(children: [
                ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    final officer = store.activeOfficerForPos(targetPos);
                    return Text(
                      officer != null
                          ? 'Arahkan kamera ke QR code milik ${officer.name} (${officer.shift}) di $targetPos'
                          : 'Arahkan kamera ke QR code di $targetPos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textCol,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                    'Pastikan QR masih aktif dan berasal dari petugas satpam.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextCol, fontSize: 11.5)),
              ]),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderCol, width: 2.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: MobileScanner(
                  controller: controller,
                  errorBuilder: (c, e, w) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          'Izin kamera belum aktif atau kamera tidak tersedia di perangkat ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subTextCol)),
                    ),
                  ),
                  onDetect: (cap) {
                    final v = cap.barcodes.firstOrNull?.rawValue;
                    if (v != null) _handleScan(v);
                  },
                ),
              ),
            ),
            PrimaryButton(
                'Batal / Kembali', () => Navigator.pop(context),
                outlined: true),
          ]),
        ),
      ),
    );
  }
}

typedef QrScreen = ScanGuardQrScreen;

// -------------------------------------------- detail publik (gaya bersih referensi)
class PublicDetailScreen extends StatelessWidget {
  final Report r;
  const PublicDetailScreen(this.r, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
        title:
        const Text('Detail Barang', style: TextStyle(fontSize: 16))),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final dark = isDark(context);
        final navyAccent = dark ? const Color(0xFF60A5FA) : kNavyPrimary;
        final found = r.type == ReportType.ditemukan;
        final mine = store.pendingClaimOf(r.id, store.email);
        final activeOfficer = store.activeOfficerForPos(r.pos);

        return ListView(padding: const EdgeInsets.all(16), children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                  aspectRatio: 4 / 3, child: ReportPhoto(r))),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(r.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              StatusChip(r.typeLabel),
            ],
          ),
          if (r.status != stActive) ...[
            const SizedBox(height: 6),
            Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(r.status)),
          ],
          const SizedBox(height: 16),

          // Kartu Informasi Terstruktur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardC(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderC(context)),
            ),
            child: Column(
              children: [
                InfoRow(
                    Icons.category_outlined, 'Kategori', r.categoryLabel),
                InfoRow(
                    Icons.calendar_today_outlined, 'Waktu', fmtDate(r.date)),
                InfoRow(
                    Icons.description_outlined, 'Ciri-ciri', r.description),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Kartu Lokasi Pos Satpam & Petugas Bertugas Saat Ini
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF132238)
                  : kNavyPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark
                    ? const Color(0xFF1E3A8A)
                    : kNavyPrimary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: navyAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on_rounded,
                      color: navyAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.pos,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: dark ? Colors.white : kNavyPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        found
                            ? 'Barang diamankan di pos satpam ini'
                            : 'Pos koordinasi laporan kehilangan',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: mutedC(context),
                        ),
                      ),
                      if (activeOfficer != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '🛡️ Petugas jaga saat ini: ${activeOfficer.name} • ${activeOfficer.shift}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? const Color(0xFF38BDF8)
                                : kToska,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardC(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderC(context)),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline,
                      size: 17, color: mutedC(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Data pelapor disembunyikan demi privasi. Hanya pelapor dan satpam yang dapat melihatnya.',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: mutedC(context),
                          height: 1.4),
                    ),
                  ),
                ]),
          ),
          const SizedBox(height: 20),
          if (r.status == stDone)
            Center(
                child: Text(
                    'Barang ini sudah diserahkan kepada pemiliknya.',
                    style: TextStyle(color: mutedC(context))))
          else if (found && mine != null) ...[
            Text('Klaim kamu menunggu verifikasi satpam.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedC(context))),
            const SizedBox(height: 10),
            PrimaryButton(
                'Pindai QR Pos Satpam',
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            QrScreen(kind: 'C', targetId: mine.id)))),
          ] else if (found)
            PrimaryButton(
                'Lapor Kepemilikan / Ajukan Klaim',
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ClaimScreen(r))))
          else
            PrimaryButton(
                'Saya Menemukan Barang Ini',
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ReportFormScreen(found: true, prefill: r)))),
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
  final answerC = TextEditingController(),
      proofC = TextEditingController(),
      lostTimeC = TextEditingController();
  DateTime lostDate = DateTime.now();
  String? photo;

  String _formatDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${fmtDate(dt)} • $hh:$mm WIB';
  }

  @override
  void initState() {
    super.initState();
    lostTimeC.text = _formatDateTime(lostDate);
  }

  Future<void> _pickLostTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: lostDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(lostDate),
    );
    if (!mounted) return;

    setState(() {
      lostDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? lostDate.hour,
        pickedTime?.minute ?? lostDate.minute,
      );
      lostTimeC.text = _formatDateTime(lostDate);
    });
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final extraProof = proofC.text.trim();
    final combinedProof = extraProof.isEmpty
        ? 'Perkiraan waktu hilang: ${lostTimeC.text}'
        : 'Perkiraan waktu hilang: ${lostTimeC.text} • $extraProof';

    final c = Claim(
      id: store.nextClaimId(),
      reportId: widget.r.id,
      claimer: store.email,
      answer: answerC.text.trim(),
      proof: combinedProof,
      photo: photo,
      date: DateTime.now(),
    );
    store.addClaim(c);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kToska,
        duration: const Duration(seconds: 5),
        content: Text(
          'Klaim terkirim! Kamu bisa scan QR di ${widget.r.pos} kapan saja lewat tab Klaim Saya.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final toskaAccent = dark ? const Color(0xFF22B8CF) : kToska;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Klaim Kepemilikan',
              style: TextStyle(fontSize: 16))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          sectionHeading(context, 'Foto Pendukung (Opsional)'),
          const SizedBox(height: 4),
          Text(
            'Unggah foto barang atau bukti pendukung lainnya jika ada.',
            style: TextStyle(fontSize: 12, color: mutedC(context)),
          ),
          const SizedBox(height: 8),
          PhotoBox(
              path: photo, onPicked: (p) => setState(() => photo = p)),
          const SizedBox(height: 16),
          Text(widget.r.name,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          AppField(
            'Kapan Terakhir Hilang',
            'Pilih tanggal & perkiraan jam terakhir terlihat',
            controller: lostTimeC,
            readOnly: true,
            icon: Icons.event_available_outlined,
            suffix: Icon(Icons.calendar_month_rounded, color: toskaAccent),
            onTap: _pickLostTime,
            validator: requiredField,
          ),
          AppField(
            'Keterangan Kepemilikan & Ciri Barang',
            'Jelaskan ciri fisik, merek, atau isi barang milikmu',
            controller: answerC,
            maxLines: 3,
            icon: Icons.fact_check_outlined,
            helper:
            'Contoh: merek barang, stiker/gantungan, isi di dalam, atau kondisi khusus untuk dicocokkan satpam.',
            validator: requiredField,
          ),
          AppField(
            'Catatan Tambahan (opsional)',
            'Info lain yang menguatkan bahwa barang ini milikmu',
            controller: proofC,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text('Verifikasi pengambilan oleh satpam di ${widget.r.pos}.',
              style: TextStyle(color: mutedC(context), fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: toskaAccent.withValues(alpha: dark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: toskaAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_circle_outlined,
                    size: 20, color: toskaAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Identitas pengklaim tercatat otomatis dari akun Google (${store.email}).',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : kNavyPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton('Kirim Klaim', _submit),
        ]),
      ),
    );
  }
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
        title: const Text('Hapus Laporan?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'Laporan "${report.name}" (${report.id}) yang belum diverifikasi akan dihapus permanen. Lanjutkan?',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48)),
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
        const SnackBar(
            content: Text('Laporan berhasil dihapus.'),
            backgroundColor: Color(0xFFE11D48)),
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
      final dark = isDark(context);
      final toskaAccent = dark ? const Color(0xFF22B8CF) : kToska;
      final activeOfficer = store.activeOfficerForPos(current.pos);

      return Scaffold(
        appBar: AppBar(
            title: const Text('Detail Laporan',
                style: TextStyle(fontSize: 16))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                  aspectRatio: 4 / 3, child: ReportPhoto(current))),
          const SizedBox(height: 14),
          Text(current.name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            StatusChip(current.typeLabel),
            StatusChip(current.status)
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardC(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderC(context)),
            ),
            child: Column(
              children: [
                InfoRow(Icons.tag, 'Kode Laporan', current.id),
                InfoRow(Icons.category_outlined, 'Kategori',
                    current.categoryLabel),
                InfoRow(Icons.description_outlined, 'Deskripsi',
                    current.description),
                InfoRow(Icons.calendar_today_outlined, 'Tanggal',
                    fmtDate(current.date)),
                InfoRow(Icons.local_police_outlined, 'Pos Satpam',
                    current.pos),
                if (activeOfficer != null)
                  InfoRow(Icons.shield_outlined, 'Petugas Jaga',
                      '${activeOfficer.name} (${activeOfficer.shift})'),
                InfoRow(Icons.person_outline, 'Pelapor', current.owner),
              ],
            ),
          ),
          if (claims.isNotEmpty) ...[
            const SizedBox(height: 14),
            sectionHeading(context, 'Klaim pada barang ini'),
            const SizedBox(height: 8),
            for (final c in claims)
              ClaimTile(c, () {
                if (store.guard) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ClaimReviewScreen(c)));
                }
              }),
          ],
          const SizedBox(height: 18),
          if (isOwner && current.status == stWait) ...[
            PrimaryButton(
              'Pindai QR Pos Satpam untuk Verifikasi',
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ScanGuardQrScreen(
                          kind: 'R', targetId: current.id))),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: toskaAccent, width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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
                    icon: Icon(Icons.edit_rounded,
                        size: 18, color: toskaAccent),
                    label: Text(
                      'Edit Laporan',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: toskaAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                          color: Color(0xFFE11D48), width: 1.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _confirmDelete(context, current),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: Color(0xFFE11D48)),
                    label: const Text('Hapus Laporan',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE11D48))),
                  ),
                ),
              ],
            ),
          ],
          if (isOwner &&
              current.type == ReportType.hilang &&
              current.isPublic) ...[
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
              m.showSnackBar(const SnackBar(
                  content: Text('Laporan disetujui dan diunggah')));
            }),
            const SizedBox(height: 10),
            PrimaryButton('Tolak Laporan', () {
              final m = ScaffoldMessenger.of(context);
              store.rejectReport(current);
              Navigator.pop(context);
              m.showSnackBar(
                  const SnackBar(content: Text('Laporan ditolak')));
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
    'match' => (Icons.auto_awesome_rounded, Colors.amber.shade800),
    'verified' => (Icons.verified_rounded, kToska),
    'claim' => (Icons.how_to_reg_rounded, kNavyPrimary),
    _ => (Icons.notifications_none_rounded, kSlateSubLabel),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final dark = isDark(context);
        final toskaAccent = dark ? const Color(0xFF22B8CF) : kToska;
        final all =
        store.notifs.where((n) => n.owner == store.email).toList();
        final list = all.where((n) => f == 'Semua' || !n.read).toList();

        return _sheetPage(
          context,
          headerHeight: 144,
          header: const BandHeader(
            'Notifikasi',
            subtitle: 'Info kecocokan & status verifikasi',
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: sectionHeading(context, 'Pesan & Pembaruan',
                        trailing: '${list.length} item'),
                  ),
                  if (all.any((n) => !n.read)) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => store.markAllRead(store.email),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Tandai dibaca',
                        style: TextStyle(
                          color: toskaAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              FilterChips(const ['Semua', 'Belum dibaca'], f,
                      (v) => setState(() => f = v)),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                      child: Text('Belum ada notifikasi',
                          style: TextStyle(color: mutedC(context)))),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cardC(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderC(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              indent: 64,
                              color: borderC(context)),
                        Material(
                          color: list[i].read
                              ? Colors.transparent
                              : toskaAccent.withValues(
                              alpha: dark ? 0.14 : 0.06),
                          child: InkWell(
                            onTap: () {
                              final n = list[i];
                              store.markRead(n);
                              if (n.type == 'match' &&
                                  n.matchIds.isNotEmpty) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => MatchScreen(n)));
                              } else if (n.reportId != null) {
                                final r = store.find(n.reportId!);
                                if (r != null) openReport(context, r);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 13),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _style(list[i].type)
                                          .$2
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                      BorderRadius.circular(11),
                                    ),
                                    child: Icon(_style(list[i].type).$1,
                                        color: _style(list[i].type).$2,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                list[i].title,
                                                style: TextStyle(
                                                  fontWeight: list[i].read
                                                      ? FontWeight.w700
                                                      : FontWeight.w800,
                                                  fontSize: 13.5,
                                                  color: dark
                                                      ? Colors.white
                                                      : kSlateHeading,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              ago(list[i].time),
                                              style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: mutedC(context)),
                                            ),
                                            if (!list[i].read) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: toskaAccent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          list[i].message,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: mutedC(context),
                                            height: 1.38,
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
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class MatchScreen extends StatelessWidget {
  final AppNotif n;
  const MatchScreen(this.n, {super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final toskaAccent = dark ? const Color(0xFF22B8CF) : kToska;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Kecocokan Barang',
              style: TextStyle(fontSize: 16))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardC(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderC(context)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_awesome, color: Colors.amber.shade800),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dicocokkan otomatis dari nama, kategori, deskripsi, pos satpam, dan tanggal. Kepemilikan tetap diverifikasi satpam.',
                style: TextStyle(
                    fontSize: 12, color: mutedC(context), height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        sectionHeading(context, 'Barang Paling Mirip'),
        const SizedBox(height: 10),
        for (var i = 0; i < n.matchIds.length; i++) ...[
          Builder(builder: (context) {
            final r = store.find(n.matchIds[i]);
            if (r == null) return const SizedBox();
            final s = i < n.scores.length ? n.scores[i] : 0.0;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openReport(context, r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardC(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderC(context)),
                ),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                          width: 76, height: 76, child: ReportPhoto(r))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                          Text(r.pos,
                              style: TextStyle(
                                  fontSize: 11, color: mutedC(context))),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: s,
                              minHeight: 8,
                              color: toskaAccent,
                              backgroundColor: borderC(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kecocokan ${(s * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: dark
                                  ? const Color(0xFFCBD5E1)
                                  : kSlateSubLabel,
                            ),
                          ),
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
}