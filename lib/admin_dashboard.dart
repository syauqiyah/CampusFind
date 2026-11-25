import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_screens.dart';
import 'core.dart';
import 'widgets.dart';

typedef EarlyAlert = Map<String, dynamic>;

class AdminDashboardScreen extends StatefulWidget {
  final String adminEmail;
  const AdminDashboardScreen({super.key, required this.adminEmail});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = FirebaseFirestore.instance;
  final _searchC = TextEditingController();

  int _selectedView = 0; // 0: Audit, 1: Alert, 2: Custody, 3: Satpam, 4: Mahasiswa, 5: Statistik
  String _searchQuery = '';

  // Form controller untuk mendaftarkan ID Satpam baru
  final _satpamFormKey = GlobalKey<FormState>();
  final _satpamIdC = TextEditingController();
  final _satpamNameC = TextEditingController();
  String _satpamPos = posList[0];
  final _satpamShiftC = TextEditingController(text: 'Pagi - Sore (07:00 - 19:00)');

  @override
  void dispose() {
    _searchC.dispose();
    _satpamIdC.dispose();
    _satpamNameC.dispose();
    _satpamShiftC.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await store.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      smoothRoute(const ChooseLoginScreen()),
          (r) => false,
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: kDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // -------------------- AKSI GATEKEEPER & MODERASI FIRESTORE --------------------

  Future<void> _addSatpamOfficer() async {
    if (!_satpamFormKey.currentState!.validate()) return;
    final id = _satpamIdC.text.trim().toUpperCase();
    final name = _satpamNameC.text.trim();
    final shift = _satpamShiftC.text.trim();

    final docRef = _db.collection('satpam_officers').doc(id);
    final existing = await docRef.get();
    if (existing.exists) {
      _showToast('ID Satpam $id sudah terdaftar!');
      return;
    }

    await docRef.set({
      'id': id,
      'name': name,
      'post': _satpamPos,
      'shift': shift.isEmpty ? 'Shift Reguler' : shift,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    store.notify(
      widget.adminEmail,
      'account',
      'ID Petugas Satpam Dibuat ($id)',
      'Admin Supervisor mendaftarkan petugas $name untuk penugasan di $_satpamPos.',
    );

    _satpamIdC.clear();
    _satpamNameC.clear();
    _showToast('Akun $id ($name) berhasil didaftarkan!');
  }

  Future<void> _toggleSatpamActive(String docId, bool currentActive, String name) async {
    await _db.collection('satpam_officers').doc(docId).update({
      'active': !currentActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    store.notify(
      widget.adminEmail,
      'account',
      !currentActive ? 'ID Satpam Diaktifkan ($docId)' : 'ID Satpam Dinonaktifkan ($docId)',
      'Status petugas $name ($docId) diubah oleh Admin Supervisor.',
    );
    _showToast(!currentActive ? 'Akun $docId diaktifkan' : 'Akun $docId dinonaktifkan');
  }

  Future<void> _toggleStudentBlock(String uid, bool currentBlocked, String email) async {
    await _db.collection('users').doc(uid).update({
      'blocked': !currentBlocked,
      'flagNote': !currentBlocked ? 'Dibekukan oleh Admin Supervisor' : 'Dipulihkan oleh Admin Supervisor',
    });
    store.notify(
      widget.adminEmail,
      'moderation',
      !currentBlocked ? 'Akun Mahasiswa Dibekukan' : 'Blokir Akun Mahasiswa Dibuka',
      'Akun $email ${!currentBlocked ? "dibekukan" : "dipulihkan"} oleh Admin Supervisor.',
    );
    _showToast(!currentBlocked ? 'Akun $email dibekukan' : 'Blokir $email dibuka');
  }

  void _openItemAuditModal(Report r) {
    final relatedClaims = store.claimsOf(r.id);
    final approvedClaim = relatedClaims.where((c) => c.status == 'Disetujui').firstOrNull;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: kGreen.withValues(alpha: 0.14),
              child: Icon(r.icon, color: kGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AUDIT CUSTODY (READ-ONLY)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kDeep),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📍 ${r.pos}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kGreen),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  r.description.isEmpty ? 'Tidak ada deskripsi tambahan.' : r.description,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Laporan: ${r.id} • Jenis: ${r.typeLabel}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Pos Penanganan: ${r.pos}', style: const TextStyle(fontSize: 12)),
                    Text('Pelapor Awal: ${r.owner} (${fmtDate(r.date)})', style: const TextStyle(fontSize: 12)),
                    Text('Status Saat Ini: ${r.status}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(
                      'Penerima / Pengklaim Sah: ${approvedClaim != null ? "${approvedClaim.claimer} (${fmtDate(approvedClaim.date)})" : "-"}',
                      style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup Audit'),
          ),
        ],
      ),
    );
  }

  // -------------------- DETEKSI EARLY WARNING REAL-TIME --------------------

  List<EarlyAlert> _computeEarlyWarnings(List<Report> reports, List<Claim> claims) {
    final List<EarlyAlert> alerts = [];

    for (final r in reports) {
      final pendingClaims = claims.where((c) => c.reportId == r.id && c.status == 'Menunggu').toList();
      final uniqueClaimers = pendingClaims.map((c) => c.claimer).toSet();
      if (uniqueClaimers.length >= 2) {
        alerts.add({
          'severity': 'high',
          'category': 'Sengketa Klaim Ganda (${uniqueClaimers.length} Mahasiswa)',
          'title': '${r.name} (${r.id})',
          'post': r.pos,
          'detail':
          'Terdapat ${uniqueClaimers.length} mahasiswa berbeda mengajukan klaim pada barang yang sama (${uniqueClaimers.join(", ")}). Periksa detail rahasia & akun indikasi spam.',
        });
      }
    }

    final now = DateTime.now();
    for (final r in reports) {
      if (r.type == ReportType.ditemukan && r.isPublic) {
        final days = now.difference(r.date).inDays;
        if (days > 7) {
          alerts.add({
            'severity': 'warning',
            'category': 'Barang Mengendap > 7 Hari ($days Hari)',
            'title': '${r.name} (${r.id})',
            'post': r.pos,
            'detail':
            'Disimpan di ${r.pos} sejak ${fmtDate(r.date)} ($days hari belum diambil pemilik). Koordinasikan pengumuman dengan fakultas.',
          });
        }
      }
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, settings]),
      builder: (context, _) {
        final dark = settings.mode == ThemeMode.dark;
        final bgColor = dark ? const Color(0xFF0A1610) : const Color(0xFFF6F8FB);
        final cardColor = dark ? const Color(0xFF14261D) : Colors.white;
        final inputFillColor = dark ? const Color(0xFF1B3327) : const Color(0xFFF8FAFC);
        final textColor = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
        final mutedColor = dark ? Colors.white60 : Colors.black54;
        final borderColor = dark ? const Color(0xFF244235) : const Color(0xFFDCEBE1);
        final isDesktop = MediaQuery.of(context).size.width >= 960;

        final reports = store.reports;
        final claims = store.claims;
        final notifs = store.notifs;
        final alerts = _computeEarlyWarnings(reports, claims);

        return Theme(
          data: Theme.of(context).copyWith(
            brightness: dark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: bgColor,
            cardColor: cardColor,
            canvasColor: cardColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kGreen,
              primary: kGreen,
              surface: cardColor,
              onSurface: textColor,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: inputFillColor,
              labelStyle: TextStyle(color: mutedColor, fontSize: 13),
              hintStyle: TextStyle(color: mutedColor, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kGreen, width: 1.6),
              ),
            ),
          ),
          child: PopScope(
            canPop: _selectedView == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_selectedView != 0) setState(() => _selectedView = 0);
            },
            child: Scaffold(
              backgroundColor: bgColor,
              body: Row(
                children: [
                  if (isDesktop) _buildLeftSidebar(notifs.length, alerts.length),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopHeader(dark, cardColor, inputFillColor, textColor, mutedColor, borderColor),
                        if (!isDesktop) _buildMobileNavBar(notifs.length, alerts.length, cardColor, textColor),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              FadeSlideIn(
                                index: 0,
                                child: _buildKpiRow(dark, reports, alerts.length, cardColor, textColor, mutedColor, borderColor),
                              ),
                              const SizedBox(height: 24),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: KeyedSubtree(
                                  key: ValueKey(_selectedView),
                                  child: _buildActiveWorkspace(
                                    dark,
                                    reports,
                                    claims,
                                    notifs,
                                    alerts,
                                    cardColor,
                                    inputFillColor,
                                    textColor,
                                    mutedColor,
                                    borderColor,
                                  ),
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
            ),
          ),
        );
      },
    );
  }

  // -------------------- SIDEBAR KIRI TEMA HIJAU CAMPUSFIND --------------------

  Widget _buildLeftSidebar(int auditCount, int alertCount) {
    return Container(
      width: 276,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08422A), kDeep, Color(0xFF137949)],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.travel_explore_rounded, color: Color(0xFFA7F3D0), size: 26),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Campus',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(6)),
                                child: const Text('Find',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('Admin Supervisor • UNESA',
                              style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('AUDITOR & WATCHDOG',
                        style: TextStyle(
                            color: Color(0xB3D1FAE5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  ),
                  _sidebarItem(0, Icons.receipt_long_rounded, 'Audit Trail Serah Terima',
                      badge: '$auditCount', badgeColor: kGreen),
                  _sidebarItem(1, Icons.notification_important_rounded, 'Peringatan Dini (Alert)',
                      badge: '$alertCount', badgeColor: const Color(0xFFE11D48)),
                  _sidebarItem(2, Icons.inventory_2_rounded, 'Pantau Custody Pos'),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('GATEKEEPER & ANALIS',
                        style: TextStyle(
                            color: Color(0xB3D1FAE5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  ),
                  _sidebarItem(3, Icons.verified_user_rounded, 'Kelola ID Satpam Pos'),
                  _sidebarItem(4, Icons.school_rounded, 'Moderasi Akun Mahasiswa'),
                  _sidebarItem(5, Icons.bar_chart_rounded, 'Analis & Statistik Kampus'),
                  const Spacer(),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Otoritas Supervisor',
                                style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 12, fontWeight: FontWeight.w800)),
                            Icon(Icons.circle, size: 9, color: Color(0xFF34D399)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Serah-terima fisik dieksekusi oleh Satpam Pos. Admin berperan sebagai Auditor Log, Gatekeeper Akun, & Analis Keamanan Kampus.',
                          style: TextStyle(color: Color(0xFFECFDF5), fontSize: 11, height: 1.45),
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

  Widget _sidebarItem(int index, IconData icon, String label, {String? badge, Color? badgeColor}) {
    final active = _selectedView == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TapScale(
        scaleDown: 0.98,
        onTap: () => setState(() => _selectedView = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: active
                ? LinearGradient(colors: [kGreen.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0.14)])
                : null,
            border: active ? const Border(left: BorderSide(color: Color(0xFF6EE7B7), width: 3.5)) : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- TOP HEADER BAR --------------------

  Widget _buildTopHeader(
      bool dark, Color cardColor, Color inputFillColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dashboard Admin Supervisor — CampusFind UNESA',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                    ),
                    child: Text('AUDITOR + GATEKEEPER',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: dark ? const Color(0xFF6EE7B7) : kDeep)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Pengawasan real-time aktivitas satpam pos, peringatan dini sengketa/endapan barang, manajemen ID petugas, & statistik keamanan kampus',
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 38,
                child: TextField(
                  controller: _searchC,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(fontSize: 12, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Cari barang, email, ID Satpam...',
                    hintStyle: TextStyle(fontSize: 12, color: mutedColor),
                    prefixIcon: Icon(Icons.search_rounded, size: 17, color: mutedColor),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: dark ? const Color(0xFF1B3327) : kLeaf.withValues(alpha: 0.55),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Ganti Tema Siang/Malam',
                onPressed: () => settings.setDark(!dark),
                icon: Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: dark ? const Color(0xFF6EE7B7) : kGreen),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [kDeep, kGreen]),
                      ),
                      alignment: Alignment.center,
                      child: const Text('KM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kemahasiswaan & Keamanan',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: textColor)),
                        Text(widget.adminEmail, style: TextStyle(fontSize: 10, color: mutedColor)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Keluar',
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavBar(int auditCount, int alertCount, Color cardColor, Color textColor) {
    final tabs = [
      ('📜 Audit ($auditCount)', 0),
      ('🚨 Alert ($alertCount)', 1),
      ('📦 Custody Pos', 2),
      ('🛡️ ID Satpam', 3),
      ('🎓 Mahasiswa', 4),
      ('📊 Statistik', 5),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: tabs.map((t) {
          final active = _selectedView == t.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t.$1,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : textColor)),
              selected: active,
              selectedColor: kGreen,
              backgroundColor: cardColor,
              onSelected: (_) => setState(() => _selectedView = t.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------- 4 KPI CARDS --------------------

  Widget _buildKpiRow(
      bool dark, List<Report> reports, int alertCount, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final resolvedCount = reports.where((r) => r.status == stDone).length;

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('satpam_officers').where('active', isEqualTo: true).snapshots(),
      builder: (context, officerSnap) {
        final activeOfficers = officerSnap.data?.docs.length ?? 0;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpiCard(dark, 'Total Laporan Terpantau', reports.length, 'Seluruh pos kampus UNESA', Icons.assignment_rounded,
                kGreen, cardColor, textColor, mutedColor, borderColor),
            _kpiCard(dark, 'Peringatan Dini Aktif', alertCount, 'Sengketa & endapan >7 hari', Icons.warning_amber_rounded,
                const Color(0xFFE11D48), cardColor, textColor, mutedColor, borderColor),
            _kpiCard(dark, 'Petugas Satpam Aktif', activeOfficers, 'Akun resmi terdaftar', Icons.shield_rounded, kDeep,
                cardColor, textColor, mutedColor, borderColor),
            _kpiCard(dark, 'Serah Terima Selesai', resolvedCount, 'Terekam audit trail', Icons.handshake_rounded,
                const Color(0xFF059669), cardColor, textColor, mutedColor, borderColor),
          ],
        );
      },
    );
  }

  Widget _kpiCard(bool dark, String title, int value, String sub, IconData icon, Color accent, Color cardColor, Color textColor,
      Color mutedColor, Color borderColor) {
    return Container(
      width: 245,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: mutedColor),
                ),
                const SizedBox(height: 4),
                AnimatedCounter(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
        ],
      ),
    );
  }

  // -------------------- ROUTER 6 MODUL SUPERVISOR --------------------

  Widget _buildActiveWorkspace(
      bool dark,
      List<Report> reports,
      List<Claim> claims,
      List<AppNotif> notifs,
      List<EarlyAlert> alerts,
      Color cardColor,
      Color inputFillColor,
      Color textColor,
      Color mutedColor,
      Color borderColor,
      ) {
    switch (_selectedView) {
      case 0:
        return _buildAuditTrailView(dark, notifs, cardColor, textColor, mutedColor, borderColor);
      case 1:
        return _buildEarlyWarningView(alerts, cardColor, textColor, mutedColor, borderColor);
      case 2:
        return _buildCustodyView(reports, claims, cardColor, textColor, mutedColor, borderColor);
      case 3:
        return _buildOfficersView(dark, cardColor, inputFillColor, textColor, mutedColor, borderColor);
      case 4:
        return _buildStudentsView(dark, cardColor, textColor, mutedColor, borderColor);
      case 5:
        return _buildAnalyticsView(reports, cardColor, textColor, mutedColor, borderColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // 0. AUDIT TRAIL SERAH TERIMA (READ-ONLY)
  Widget _buildAuditTrailView(
      bool dark, List<AppNotif> notifs, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final filtered = notifs.where((n) {
      if (_searchQuery.isEmpty) return true;
      return n.title.toLowerCase().contains(_searchQuery) ||
          n.message.toLowerCase().contains(_searchQuery) ||
          n.owner.toLowerCase().contains(_searchQuery);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audit Trail & Watchdog Serah Terima (Read-Only)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 3),
                      Text('Jejak transparan real-time aktivitas satpam pos, pengajuan klaim, hingga penyerahan fisik',
                          style: TextStyle(fontSize: 12, color: mutedColor)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('● Watchdog Real-Time Aktif',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800, color: dark ? const Color(0xFF6EE7B7) : kDeep)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('Belum ada aktivitas tercatat pada log audit Firestore.',
                    style: TextStyle(fontSize: 13, color: mutedColor)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (context, i) {
                final n = filtered[i];
                final isClaim = n.type == 'claim';
                final isVerified = n.type == 'verified';
                final badgeColor = isVerified ? kGreen : (isClaim ? const Color(0xFFF59E0B) : kDeep);

                return FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isVerified
                                ? Icons.handshake_rounded
                                : (isClaim ? Icons.notifications_active_rounded : Icons.shield_rounded),
                            color: badgeColor,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${n.title} (${n.owner})',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: dark ? const Color(0xFF6EE7B7) : kDeep)),
                              const SizedBox(height: 3),
                              Text(n.message, style: TextStyle(fontSize: 12.5, color: textColor, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(ago(n.time), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedColor)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // 1. EARLY WARNING ALERTS
  Widget _buildEarlyWarningView(List<EarlyAlert> alerts, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifikasi Peringatan Dini (Early Warning Watchdog)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                    const SizedBox(height: 3),
                    Text('Deteksi otomatis sengketa klaim ganda (≥2 mahasiswa) & barang temuan mengendap > 7 hari di pos',
                        style: TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${alerts.length} Alert Aktif',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE11D48))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_outlined, color: kGreen, size: 36),
                  SizedBox(height: 8),
                  Text('Kondisi Aman — Tidak Ada Peringatan Dini',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Tidak ditemukan sengketa klaim ganda maupun barang mengendap lebih dari 7 hari.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          else
            for (var i = 0; i < alerts.length; i++)
              Builder(builder: (context) {
                final al = alerts[i];
                final isHigh = al['severity'] == 'high';
                final c = isHigh ? const Color(0xFFE11D48) : const Color(0xFFF59E0B);
                return FadeSlideIn(
                  index: i,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
                              child: Text(al['category'],
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),
                            Text(al['post'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mutedColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(al['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                        const SizedBox(height: 4),
                        Text(al['detail'], style: TextStyle(fontSize: 12, color: mutedColor, height: 1.4)),
                      ],
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }

  // 2. MONITORING CUSTODY POS (READ-ONLY)
  Widget _buildCustodyView(
      List<Report> reports, List<Claim> claims, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final filtered = reports.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.name.toLowerCase().contains(_searchQuery) ||
          r.id.toLowerCase().contains(_searchQuery) ||
          r.pos.toLowerCase().contains(_searchQuery) ||
          r.owner.toLowerCase().contains(_searchQuery);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monitoring Seluruh Barang & Custody Pos (Read-Only)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 3),
                Text('Admin memantau penyimpanan pos & status serah-terima secara read-only (eksekusi fisik dilakukan Satpam Pos)',
                    style: TextStyle(fontSize: 12, color: mutedColor)),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Belum ada data barang yang tercatat.', style: TextStyle(color: mutedColor))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: mutedColor),
                columns: const [
                  DataColumn(label: Text('ID & BARANG')),
                  DataColumn(label: Text('JENIS')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('POS PENYIMPANAN')),
                  DataColumn(label: Text('PENERIMA SAH')),
                  DataColumn(label: Text('AUDIT')),
                ],
                rows: filtered.map((r) {
                  final approved = claims.where((c) => c.reportId == r.id && c.status == 'Disetujui').firstOrNull;
                  return DataRow(
                    cells: [
                      DataCell(Row(
                        children: [
                          Icon(r.icon, size: 18, color: kGreen),
                          const SizedBox(width: 8),
                          Text('${r.id} • ${r.name}',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: textColor)),
                        ],
                      )),
                      DataCell(Text(r.typeLabel, style: TextStyle(fontSize: 12, color: textColor))),
                      DataCell(_statusPill(r.status)),
                      DataCell(Text(r.pos, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor))),
                      DataCell(Text(approved?.claimer ?? '-',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGreen))),
                      DataCell(
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(side: BorderSide(color: borderColor)),
                          onPressed: () => _openItemAuditModal(r),
                          child: const Text('Detail Audit',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kGreen)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    Color c = kGreen;
    if (status == stDone) c = kDeep;
    if (status == stClaimed || status == stWait) c = const Color(0xFFF59E0B);
    if (status == stRejected) c = const Color(0xFFE11D48);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c)),
    );
  }

  // 3. GATEKEEPER: KELOLA ID SATPAM POS (INPUT TERANG & BERSIH)
  Widget _buildOfficersView(
      bool dark, Color cardColor, Color inputFillColor, Color textColor, Color mutedColor, Color borderColor) {
    InputDecoration cleanInput(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: inputFillColor,
      labelStyle: TextStyle(color: mutedColor, fontSize: 13),
      hintStyle: TextStyle(color: mutedColor, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGreen, width: 1.6),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;

        final formCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Form(
            key: _satpamFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('GATEKEEPER OTORITAS',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800, color: dark ? const Color(0xFF6EE7B7) : kDeep)),
                ),
                const SizedBox(height: 8),
                Text('Daftarkan ID Satpam Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 4),
                Text('Hanya Admin Supervisor yang berhak menerbitkan ID resmi petugas satpam & menentukan pos jaga.',
                    style: TextStyle(fontSize: 12, color: mutedColor)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _satpamIdC,
                  style: TextStyle(color: textColor, fontSize: 13.5),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'ID Satpam wajib diisi' : null,
                  decoration: cleanInput('ID Resmi Satpam', hint: 'Contoh: SATPAM-POS1'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _satpamNameC,
                  style: TextStyle(color: textColor, fontSize: 13.5),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama petugas wajib diisi' : null,
                  decoration: cleanInput('Nama Petugas', hint: 'Contoh: Pak Budi Santoso'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _satpamPos,
                  dropdownColor: cardColor,
                  style: TextStyle(color: textColor, fontSize: 13.5),
                  items: posList.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: textColor)))).toList(),
                  onChanged: (v) => setState(() => _satpamPos = v ?? posList[0]),
                  decoration: cleanInput('Lokasi Pos Jaga'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _satpamShiftC,
                  style: TextStyle(color: textColor, fontSize: 13.5),
                  decoration: cleanInput('Jadwal Shift'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addSatpamOfficer,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Buat Akun Petugas (role: satpam)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        );

        final listCard = Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daftar Akun Petugas Satpam Terdaftar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                    const SizedBox(height: 3),
                    Text('Aktifkan atau nonaktifkan akses petugas pos lapangan saat pergantian personel',
                        style: TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('satpam_officers').snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text('Belum ada ID Satpam terdaftar. Silakan daftarkan di panel samping.',
                            style: TextStyle(fontSize: 12.5, color: mutedColor)),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final data = d.data() as Map<String, dynamic>;
                      final active = (data['active'] as bool?) ?? true;
                      final name = (data['name'] as String?) ?? '-';
                      return FadeSlideIn(
                        index: i,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(d.id,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: dark ? const Color(0xFF6EE7B7) : kDeep)),
                              ),
                              const SizedBox(width: 8),
                              Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('📍 ${data['post'] ?? '-'} • ${data['shift'] ?? '-'}',
                                style: TextStyle(fontSize: 12, color: mutedColor)),
                          ),
                          trailing: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: active ? kGreen : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _toggleSatpamActive(d.id, active, name),
                            child: Text(active ? '● Aktif Bertugas' : 'Nonaktif',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: formCard),
              const SizedBox(width: 20),
              Expanded(child: listCard),
            ],
          );
        }
        return Column(children: [formCard, const SizedBox(height: 20), listCard]);
      },
    );
  }

  // 4. MODERASI & PEMBEKUAN AKUN MAHASISWA
  Widget _buildStudentsView(bool dark, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Moderasi & Pembekuan Akun Warga UNESA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 3),
                Text('Bekukan akun mahasiswa/warga kampus yang terbukti membuat laporan palsu, spam, atau klaim fiktif',
                    style: TextStyle(fontSize: 12, color: mutedColor)),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(20), child: ShimmerTileList(count: 3));
              }
              final docs = (snap.data?.docs ?? []).where((d) {
                final data = d.data() as Map<String, dynamic>;
                final email = (data['email'] ?? '').toString().toLowerCase();
                final name = (data['name'] ?? '').toString().toLowerCase();
                if (_searchQuery.isEmpty) return true;
                return email.contains(_searchQuery) || name.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(child: Text('Belum ada akun warga UNESA terdaftar.', style: TextStyle(color: mutedColor))),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                itemBuilder: (context, i) {
                  final u = docs[i];
                  final data = u.data() as Map<String, dynamic>;
                  final email = (data['email'] as String?) ?? '-';
                  final role = (data['role'] as String?) ?? 'student';
                  final blocked = (data['blocked'] as bool?) ?? false;
                  final note = (data['flagNote'] as String?) ?? 'Akun terverifikasi UNESA';

                  return FadeSlideIn(
                    index: i,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: kGreen.withValues(alpha: 0.14),
                        child: Icon(role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.school_rounded, color: kGreen),
                      ),
                      title: Text('${data['name'] ?? email} ($email)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                      subtitle: Text('Role: $role • $note', style: TextStyle(fontSize: 12, color: mutedColor)),
                      trailing: role == 'admin'
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1B3327) : kLeaf,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'Admin Supervisor',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: dark ? const Color(0xFF6EE7B7) : kDeep,
                          ),
                        ),
                      )
                          : FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: blocked ? kGreen : const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _toggleStudentBlock(u.id, blocked, email),
                        child: Text(
                          blocked ? 'Pulihkan Akun' : 'Bekukan Akun',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. ANALIS & STATISTIK AREA KAMPUS (REAL-TIME DARI FIRESTORE)
  Widget _buildAnalyticsView(List<Report> reports, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final totalReports = reports.length;
    final resolvedReports = reports.where((r) => r.status == stDone).length;
    final recoveryRate = totalReports == 0 ? 0 : ((resolvedReports / totalReports) * 100).round();

    final areaCounts = <String, (int total, int done)>{};
    for (final r in reports) {
      final prev = areaCounts[r.pos] ?? (0, 0);
      areaCounts[r.pos] = (prev.$1 + 1, prev.$2 + (r.status == stDone ? 1 : 0));
    }
    final sortedAreas = areaCounts.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1));

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;

        final hotspotCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rekapitulasi Area Rawan Kehilangan & Evaluasi CCTV',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 3),
              Text('Distribusi laporan masuk vs rasio pengembalian barang per Pos Satpam',
                  style: TextStyle(fontSize: 12, color: mutedColor)),
              const SizedBox(height: 16),
              if (sortedAreas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Statistik area akan terisi otomatis setelah ada laporan masuk.',
                        style: TextStyle(fontSize: 12.5, color: mutedColor)),
                  ),
                )
              else
                for (var i = 0; i < sortedAreas.length; i++)
                  Builder(builder: (context) {
                    final entry = sortedAreas[i];
                    final total = entry.value.$1;
                    final done = entry.value.$2;
                    final ratio = total == 0 ? 0.0 : done / total;
                    final targetBar = totalReports == 0 ? 0.0 : (total / totalReports).clamp(0.08, 1.0);
                    final cctvHint = total >= 3
                        ? 'Titik rawan tinggi — direkomendasikan evaluasi & penambahan kamera CCTV'
                        : 'Cakupan pengawasan pos terpantau normal';

                    return FadeSlideIn(
                      index: i,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$done/$total Selesai (${(ratio * 100).round()}%)',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kGreen)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: targetBar),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (_, val, __) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: val,
                                  minHeight: 8,
                                  backgroundColor: borderColor,
                                  valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('📹 Evaluasi Keamanan: $cctvHint', style: TextStyle(fontSize: 11.5, color: mutedColor)),
                          ],
                        ),
                      ),
                    );
                  }),
            ],
          ),
        );

        final kpiSummaryCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('KPI KEAMANAN BULANAN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kDeep)),
              ),
              const SizedBox(height: 10),
              Text('Tingkat Keberhasilan Pengembalian',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [kDeep, kGreen]),
                ),
                child: Column(
                  children: [
                    AnimatedCounter(
                      recoveryRate,
                      suffix: '%',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text('$resolvedReports dari $totalReports barang kembali ke pemilik',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFECFDF5))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Data real-time ini menjadi bahan laporan evaluasi bulanan bagian Kemahasiswaan & Kepala Keamanan UNESA untuk penjadwalan patroli serta titik CCTV.',
                style: TextStyle(fontSize: 12, color: mutedColor, height: 1.45),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showToast('Rekap Evaluasi Keamanan UNESA ($totalReports laporan) siap dicetak!'),
                  icon: const Icon(Icons.description_rounded, size: 18),
                  label: const Text('Ekspor Rekap Evaluasi Bulanan',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ],
          ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: hotspotCard),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: kpiSummaryCard),
            ],
          );
        }
        return Column(children: [hotspotCard, const SizedBox(height: 20), kpiSummaryCard]);
      },
    );
  }
}