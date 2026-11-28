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

  static const Color _kToskaMain = kToska;
  static const Color _kNavyMain = kNavyPrimary;
  static const Color _kToskaBright = Color(0xFF22B8CF);
  static const Color _kSkyAccent = Color(0xFF38BDF8);

  static const List<String> _shiftPresets = [
    'Shift Pagi (07.00 - 14.00 WIB)',
    'Shift Sore (14.00 - 21.00 WIB)',
    'Shift Malam (21.00 - 07.00 WIB)',
    'Shift Full (07.00 - 19.00 WIB)',
  ];

  int _selectedView = 0;
  String _searchQuery = '';
  List<String> _extraPosts = [];

  final _satpamFormKey = GlobalKey<FormState>();
  final _satpamIdC = TextEditingController();
  final _satpamNameC = TextEditingController();
  String? _satpamPos;
  String _selectedShiftPreset = _shiftPresets[0];
  final _satpamShiftC =
      TextEditingController(text: 'Shift Pagi (07.00 - 14.00 WIB)');

  final _newPosC = TextEditingController();
  final _newPosAreaC = TextEditingController();

  List<String> get _allPosList {
    final merged = List<String>.from(posList);
    for (final p in _extraPosts) {
      if (!merged.any((m) => m.toLowerCase() == p.toLowerCase())) {
        merged.add(p);
      }
    }
    return merged;
  }

  @override
  void initState() {
    super.initState();
    _loadCampusPosts();
  }

  Future<void> _loadCampusPosts() async {
    try {
      final snap = await _db.collection('campus_posts').get();
      final loaded = snap.docs
          .map((d) => (d.data()['name'] as String?)?.trim() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() => _extraPosts = loaded);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchC.dispose();
    _satpamIdC.dispose();
    _satpamNameC.dispose();
    _satpamShiftC.dispose();
    _newPosC.dispose();
    _newPosAreaC.dispose();
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
        backgroundColor: _kNavyMain,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> _resolveShiftConflictIfAny({
    required String posName,
    required String shiftStr,
    String? excludeOfficerId,
  }) async {
    final snap = await _db
        .collection('satpam_officers')
        .where('post', isEqualTo: posName)
        .where('active', isEqualTo: true)
        .get();

    final conflicts = snap.docs.where((d) {
      if (excludeOfficerId != null &&
          d.id.toUpperCase() == excludeOfficerId.toUpperCase()) {
        return false;
      }
      final otherShift = (d.data()['shift'] as String?) ?? '';
      return otherShift.trim().toLowerCase() == shiftStr.trim().toLowerCase();
    }).toList();

    if (conflicts.isEmpty || !mounted) return true;

    final names = conflicts
        .map((c) => '${c.data()['name'] ?? c.id} (${c.id})')
        .join(', ');

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Jadwal Shift Sama Terdeteksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          'Di $posName pada "$shiftStr" saat ini sudah terdaftar petugas aktif: $names.\n\nApakah Anda ingin menonaktifkan petugas lama (Tukar Shift / Override) atau tetap menyimpannya sebagai petugas pendamping?',
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Batal'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: const Text('Tetap Simpan Berdua'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kToskaMain),
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: const Text('Ganti & Nonaktifkan Lama'),
          ),
        ],
      ),
    );

    if (action == null || action == 'cancel') return false;
    if (action == 'replace') {
      for (final c in conflicts) {
        await _db.collection('satpam_officers').doc(c.id).update({
          'active': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return true;
  }

  Future<void> _addCampusPos() async {
    final rawName = _newPosC.text.trim();
    if (rawName.isEmpty) {
      _showToast('Nama Pos Satpam tidak boleh kosong!');
      return;
    }
    final existingAll = _allPosList.map((e) => e.toLowerCase()).toSet();
    if (existingAll.contains(rawName.toLowerCase())) {
      _showToast('Pos "$rawName" sudah terdaftar!');
      return;
    }
    final areaNote = _newPosAreaC.text.trim();
    final docId = rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    await _db.collection('campus_posts').doc(docId).set({
      'name': rawName,
      'area': areaNote.isEmpty ? 'Area Kampus UNESA' : areaNote,
      'active': true,
      'createdBy': widget.adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _extraPosts = [..._extraPosts, rawName];
    });

    store.notify(
      widget.adminEmail,
      'system',
      'Pos Satpam Baru Ditambahkan',
      'Admin Supervisor menambahkan titik layanan baru: $rawName.',
    );

    _newPosC.clear();
    _newPosAreaC.clear();
    _showToast('Pos "$rawName" berhasil ditambahkan!');
  }

  Future<void> _deleteCampusPos(String docId, String posName) async {
    await _db.collection('campus_posts').doc(docId).delete();
    setState(() {
      _extraPosts.removeWhere((p) => p.toLowerCase() == posName.toLowerCase());
      if (_satpamPos == posName) _satpamPos = null;
    });
    _showToast('Pos "$posName" dihapus dari daftar pos tambahan.');
  }

  Future<void> _addSatpamOfficer() async {
    if (!_satpamFormKey.currentState!.validate()) return;
    final availablePos = _allPosList;
    final chosenPos = (_satpamPos != null && availablePos.contains(_satpamPos))
        ? _satpamPos!
        : availablePos.first;

    final id = _satpamIdC.text.trim().toUpperCase();
    final name = _satpamNameC.text.trim();
    final shift = _satpamShiftC.text.trim().isEmpty
        ? _shiftPresets[0]
        : _satpamShiftC.text.trim();

    final docRef = _db.collection('satpam_officers').doc(id);
    final existing = await docRef.get();
    if (existing.exists) {
      _showToast('ID Satpam $id sudah terdaftar!');
      return;
    }

    final proceed = await _resolveShiftConflictIfAny(
      posName: chosenPos,
      shiftStr: shift,
      excludeOfficerId: id,
    );
    if (!proceed) return;

    await docRef.set({
      'id': id,
      'name': name,
      'post': chosenPos,
      'shift': shift,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    store.notify(
      widget.adminEmail,
      'account',
      'ID Petugas Satpam Dibuat ($id)',
      'Admin Supervisor mendaftarkan petugas $name untuk penugasan di $chosenPos ($shift).',
    );

    _satpamIdC.clear();
    _satpamNameC.clear();
    _showToast('Akun $id ($name) berhasil didaftarkan di $chosenPos!');
  }

  Future<void> _openEditOfficerShiftDialog(
    String docId,
    Map<String, dynamic> data,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) async {
    final availablePos = _allPosList;
    String editPos = (data['post'] as String?) ?? availablePos.first;
    if (!availablePos.contains(editPos)) {
      editPos = availablePos.first;
    }
    final shiftCtrl = TextEditingController(
      text: (data['shift'] as String?) ?? _shiftPresets[0],
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: borderColor),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kToskaMain.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: _kToskaMain, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atur Pos & Shift ($docId)',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                    ),
                    Text(
                      (data['name'] as String?) ?? '-',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: editPos,
                  dropdownColor: cardColor,
                  style: TextStyle(color: textColor, fontSize: 13),
                  items: availablePos
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, style: TextStyle(color: textColor))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => editPos = v);
                  },
                  decoration:
                      const InputDecoration(labelText: 'Penempatan Pos Jaga'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _shiftPresets.map((preset) {
                    final selected = shiftCtrl.text.trim() == preset;
                    return ChoiceChip(
                      label: Text(
                        preset.split(' (').first,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : textColor,
                        ),
                      ),
                      selected: selected,
                      selectedColor: _kToskaMain,
                      onSelected: (_) {
                        setDialogState(() {
                          shiftCtrl.text = preset;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shiftCtrl,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Keterangan & Jam Shift',
                    hintText: 'Contoh: Shift Pagi (07.00 - 14.00 WIB)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kToskaMain),
              onPressed: () async {
                final newShift = shiftCtrl.text.trim().isEmpty
                    ? _shiftPresets[0]
                    : shiftCtrl.text.trim();
                final proceed = await _resolveShiftConflictIfAny(
                  posName: editPos,
                  shiftStr: newShift,
                  excludeOfficerId: docId,
                );
                if (!proceed) return;

                await _db.collection('satpam_officers').doc(docId).update({
                  'post': editPos,
                  'shift': newShift,
                  'active': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                store.notify(
                  widget.adminEmail,
                  'account',
                  'Jadwal Shift Diperbarui ($docId)',
                  'Petugas ${data['name'] ?? docId} dijadwalkan di $editPos ($newShift).',
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _showToast('Penugasan $docId diperbarui ke $editPos!');
              },
              child: const Text('Simpan Jadwal'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSatpamActive(
      String docId, bool currentActive, String name) async {
    await _db.collection('satpam_officers').doc(docId).update({
      'active': !currentActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    store.notify(
      widget.adminEmail,
      'account',
      !currentActive
          ? 'ID Satpam Diaktifkan ($docId)'
          : 'ID Satpam Dinonaktifkan ($docId)',
      'Status petugas $name ($docId) diubah oleh Admin Supervisor.',
    );
    _showToast(
        !currentActive ? 'Akun $docId diaktifkan' : 'Akun $docId dinonaktifkan');
  }

  Future<void> _toggleStudentBlock(
      String uid, bool currentBlocked, String email) async {
    await _db.collection('users').doc(uid).update({
      'blocked': !currentBlocked,
      'flagNote': !currentBlocked
          ? 'Dibekukan oleh Admin Supervisor'
          : 'Dipulihkan oleh Admin Supervisor',
    });
    store.notify(
      widget.adminEmail,
      'moderation',
      !currentBlocked
          ? 'Akun Mahasiswa Dibekukan'
          : 'Blokir Akun Mahasiswa Dibuka',
      'Akun $email ${!currentBlocked ? "dibekukan" : "dipulihkan"} oleh Admin Supervisor.',
    );
    _showToast(!currentBlocked ? 'Akun $email dibekukan' : 'Blokir $email dibuka');
  }

  void _openItemAuditModal(Report r, List<Map<String, dynamic>> guardsAtPos) {
    final relatedClaims = store.claimsOf(r.id);
    final approvedClaim =
        relatedClaims.where((c) => c.status == 'Disetujui').firstOrNull;
    final onDutyNow = guardsAtPos
        .where((g) => isShiftActiveNow((g['shift'] as String?) ?? ''))
        .toList();

    final guardSummary = guardsAtPos.isEmpty
        ? 'Belum ada petugas aktif terdaftar di ${r.pos}'
        : guardsAtPos.map((g) {
            final shift = (g['shift'] as String?) ?? 'Shift Reguler';
            final isNow = isShiftActiveNow(shift);
            final tag = isNow ? ' [● BERTUGAS SEKARANG]' : '';
            return '${g['name']} (${g['id']}) • $shift$tag';
          }).join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _kToskaMain.withValues(alpha: 0.14),
              child: Icon(r.icon, color: _kToskaMain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kToskaMain.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AUDIT CUSTODY & PENJAGA POS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kNavyMain),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(r.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 470,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📍 Lokasi Penyimpanan: ${r.pos}',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _kToskaMain),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kNavyMain.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kNavyMain.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onDutyNow.isNotEmpty
                          ? '🛡️ PETUGAS JAGA SHIFT SEKARANG & TERDAFTAR'
                          : '🛡️ PETUGAS PENJAGA POS TERDAFTAR',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _kToskaMain),
                    ),
                    const SizedBox(height: 4),
                    Text(guardSummary,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4)),
                  ],
                ),
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
                  r.description.isEmpty
                      ? 'Tidak ada deskripsi tambahan.'
                      : r.description,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kToskaMain.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kToskaMain.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Laporan: ${r.id} • Jenis: ${r.typeLabel}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Pos Penanganan: ${r.pos}',
                        style: const TextStyle(fontSize: 12)),
                    Text('Pelapor Awal: ${r.owner} (${fmtDate(r.date)})',
                        style: const TextStyle(fontSize: 12)),
                    Text('Status Saat Ini: ${r.status}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(
                      'Penerima / Pengklaim Sah: ${approvedClaim != null ? "${approvedClaim.claimer} (${fmtDate(approvedClaim.date)})" : "-"}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kToskaMain,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kToskaMain),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup Audit'),
          ),
        ],
      ),
    );
  }

  List<EarlyAlert> _computeEarlyWarnings(
      List<Report> reports, List<Claim> claims) {
    final List<EarlyAlert> alerts = [];
    for (final r in reports) {
      final pendingClaims = claims
          .where((c) => c.reportId == r.id && c.status == 'Menunggu')
          .toList();
      final uniqueClaimers = pendingClaims.map((c) => c.claimer).toSet();
      if (uniqueClaimers.length >= 2) {
        alerts.add({
          'severity': 'high',
          'category':
              'Sengketa Klaim Ganda (${uniqueClaimers.length} Mahasiswa)',
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
        final bgColor =
            dark ? const Color(0xFF0A111E) : const Color(0xFFF4F7FB);
        final cardColor = dark ? const Color(0xFF111D30) : Colors.white;
        final inputFillColor =
            dark ? const Color(0xFF16253D) : const Color(0xFFF8FAFC);
        final textColor =
            dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
        final mutedColor = dark ? Colors.white60 : Colors.black54;
        final borderColor =
            dark ? const Color(0xFF1E3250) : const Color(0xFFDCE6F2);
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
              seedColor: _kToskaMain,
              primary: _kToskaMain,
              surface: cardColor,
              onSurface: textColor,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: inputFillColor,
              labelStyle: TextStyle(color: mutedColor, fontSize: 13),
              hintStyle: TextStyle(color: mutedColor, fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                borderSide: BorderSide(
                    color: dark ? _kToskaBright : _kToskaMain, width: 1.6),
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
                        _buildTopHeader(dark, cardColor, inputFillColor,
                            textColor, mutedColor, borderColor),
                        if (!isDesktop)
                          _buildMobileNavBar(notifs.length, alerts.length,
                              cardColor, textColor),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              FadeSlideIn(
                                index: 0,
                                child: _buildKpiRow(
                                    dark,
                                    reports,
                                    alerts.length,
                                    cardColor,
                                    textColor,
                                    mutedColor,
                                    borderColor),
                              ),
                              const SizedBox(height: 24),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                            begin: const Offset(0, 0.02),
                                            end: Offset.zero)
                                        .animate(anim),
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

  Widget _buildLeftSidebar(int auditCount, int alertCount) {
    return Container(
      width: 278,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071538), _kNavyMain, Color(0xFF103E78)],
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
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.travel_explore_rounded,
                            color: _kSkyAccent, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Campus',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: _kToskaMain,
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Text('Find',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('Admin Supervisor • UNESA',
                              style: TextStyle(
                                  color: Color(0xFFBAE6FD),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('AUDITOR & CUSTODY',
                        style: TextStyle(
                            color: Color(0xB3BAE6FD),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ),
                  _sidebarItem(0, Icons.receipt_long_rounded,
                      'Audit Trail Serah Terima',
                      badge: '$auditCount', badgeColor: _kToskaMain),
                  _sidebarItem(1, Icons.notification_important_rounded,
                      'Peringatan Dini (Alert)',
                      badge: '$alertCount',
                      badgeColor: const Color(0xFFE11D48)),
                  _sidebarItem(2, Icons.inventory_2_rounded,
                      'Custody & Penjaga Barang'),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('POS, SHIFT & GATEKEEPER',
                        style: TextStyle(
                            color: Color(0xB3BAE6FD),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ),
                  _sidebarItem(
                      3, Icons.verified_user_rounded, 'Pos & Shift Satpam'),
                  _sidebarItem(
                      4, Icons.school_rounded, 'Moderasi Akun Mahasiswa'),
                  _sidebarItem(
                      5, Icons.bar_chart_rounded, 'Analis & Statistik Kampus'),
                  const Spacer(),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Otoritas Supervisor',
                                style: TextStyle(
                                    color: _kSkyAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                            Icon(Icons.circle, size: 9, color: _kToskaBright),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Kelola titik pos jaga, penjadwalan shift satpam, moderasi akun, serta pantau lokasi & petugas penjaga barang.',
                          style: TextStyle(
                              color: Color(0xFFE0F2FE),
                              fontSize: 11,
                              height: 1.45),
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

  Widget _sidebarItem(int index, IconData icon, String label,
      {String? badge, Color? badgeColor}) {
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
                ? LinearGradient(colors: [
                    _kToskaMain.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.14)
                  ])
                : null,
            border: active
                ? const Border(
                    left: BorderSide(color: _kSkyAccent, width: 3.5))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool dark, Color cardColor, Color inputFillColor,
      Color textColor, Color mutedColor, Color borderColor) {
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
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kToskaMain.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _kToskaMain.withValues(alpha: 0.3)),
                    ),
                    child: Text('AUDITOR + GATEKEEPER',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: dark ? _kSkyAccent : _kNavyMain)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Pengawasan real-time barang & petugas penjaga pos, manajemen titik pos & shift satpam, serta statistik keamanan UNESA',
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
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(fontSize: 12, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Cari barang, pos, ID Satpam...',
                    hintStyle: TextStyle(fontSize: 12, color: mutedColor),
                    prefixIcon:
                        Icon(Icons.search_rounded, size: 17, color: mutedColor),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Ganti Tema Siang/Malam',
                onPressed: () => settings.setDark(!dark),
                icon: Icon(
                    dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: dark ? _kSkyAccent : _kToskaMain),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        gradient: const LinearGradient(
                            colors: [_kNavyMain, _kToskaMain]),
                      ),
                      alignment: Alignment.center,
                      child: const Text('KM',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kemahasiswaan & Keamanan',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: textColor)),
                        Text(widget.adminEmail,
                            style: TextStyle(fontSize: 10, color: mutedColor)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Keluar',
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded,
                          size: 18, color: Colors.redAccent),
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

  Widget _buildMobileNavBar(
      int auditCount, int alertCount, Color cardColor, Color textColor) {
    final tabs = [
      ('📜 Audit ($auditCount)', 0),
      ('🚨 Alert ($alertCount)', 1),
      ('📦 Custody & Penjaga', 2),
      ('🛡️ Pos & Shift', 3),
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
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.white : textColor)),
              selected: active,
              selectedColor: _kToskaMain,
              backgroundColor: cardColor,
              onSelected: (_) => setState(() => _selectedView = t.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKpiRow(bool dark, List<Report> reports, int alertCount,
      Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final resolvedCount = reports.where((r) => r.status == stDone).length;

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('satpam_officers')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, officerSnap) {
        final activeDocs = officerSnap.data?.docs ?? [];
        final onDutyNowCount = activeDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return isShiftActiveNow((data['shift'] as String?) ?? '');
        }).length;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpiCard(
                dark,
                'Total Laporan Terpantau',
                reports.length,
                '${_allPosList.length} Pos Jaga UNESA',
                Icons.assignment_rounded,
                _kToskaMain,
                cardColor,
                textColor,
                mutedColor,
                borderColor),
            _kpiCard(
                dark,
                'Peringatan Dini Aktif',
                alertCount,
                'Sengketa & endapan >7 hari',
                Icons.warning_amber_rounded,
                const Color(0xFFE11D48),
                cardColor,
                textColor,
                mutedColor,
                borderColor),
            _kpiCard(
                dark,
                'Petugas Jaga Shift Ini',
                onDutyNowCount,
                'Dari ${activeDocs.length} akun aktif',
                Icons.shield_rounded,
                dark ? _kSkyAccent : _kNavyMain,
                cardColor,
                textColor,
                mutedColor,
                borderColor),
            _kpiCard(
                dark,
                'Serah Terima Selesai',
                resolvedCount,
                'Terekam audit trail',
                Icons.handshake_rounded,
                const Color(0xFF0284C7),
                cardColor,
                textColor,
                mutedColor,
                borderColor),
          ],
        );
      },
    );
  }

  Widget _kpiCard(
      bool dark,
      String title,
      int value,
      String sub,
      IconData icon,
      Color accent,
      Color cardColor,
      Color textColor,
      Color mutedColor,
      Color borderColor) {
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
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: mutedColor),
                ),
                const SizedBox(height: 4),
                AnimatedCounter(value,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
        ],
      ),
    );
  }

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
        return _buildAuditTrailView(
            dark, notifs, cardColor, textColor, mutedColor, borderColor);
      case 1:
        return _buildEarlyWarningView(
            alerts, cardColor, textColor, mutedColor, borderColor);
      case 2:
        return _buildCustodyView(
            dark, reports, claims, cardColor, textColor, mutedColor, borderColor);
      case 3:
        return _buildOfficersView(dark, cardColor, inputFillColor, textColor,
            mutedColor, borderColor);
      case 4:
        return _buildStudentsView(
            dark, cardColor, textColor, mutedColor, borderColor);
      case 5:
        return _buildAnalyticsView(
            reports, cardColor, textColor, mutedColor, borderColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAuditTrailView(bool dark, List<AppNotif> notifs, Color cardColor,
      Color textColor, Color mutedColor, Color borderColor) {
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
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor)),
                      const SizedBox(height: 3),
                      Text(
                          'Jejak transparan real-time aktivitas satpam pos, pengajuan klaim, hingga penyerahan fisik',
                          style: TextStyle(fontSize: 12, color: mutedColor)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kToskaMain.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('● Watchdog Real-Time Aktif',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: dark ? _kSkyAccent : _kNavyMain)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                    'Belum ada aktivitas tercatat pada log audit Firestore.',
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
                final badgeColor = isVerified
                    ? _kToskaMain
                    : (isClaim ? const Color(0xFFF59E0B) : _kNavyMain);

                return FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
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
                                : (isClaim
                                    ? Icons.notifications_active_rounded
                                    : Icons.shield_rounded),
                            color: dark && badgeColor == _kNavyMain
                                ? _kSkyAccent
                                : badgeColor,
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
                                      color: dark ? _kSkyAccent : _kNavyMain)),
                              const SizedBox(height: 3),
                              Text(n.message,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: textColor,
                                      height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(ago(n.time),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: mutedColor)),
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

  Widget _buildEarlyWarningView(List<EarlyAlert> alerts, Color cardColor,
      Color textColor, Color mutedColor, Color borderColor) {
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
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                    const SizedBox(height: 3),
                    Text(
                        'Deteksi otomatis sengketa klaim ganda (≥2 mahasiswa) & barang temuan mengendap > 7 hari di pos',
                        style: TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${alerts.length} Alert Aktif',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE11D48))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _kToskaMain.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_outlined, color: _kToskaMain, size: 36),
                  SizedBox(height: 8),
                  Text('Kondisi Aman — Tidak Ada Peringatan Dini',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                      'Tidak ditemukan sengketa klaim ganda maupun barang mengendap lebih dari 7 hari.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          else
            for (var i = 0; i < alerts.length; i++)
              Builder(builder: (context) {
                final al = alerts[i];
                final isHigh = al['severity'] == 'high';
                final c = isHigh
                    ? const Color(0xFFE11D48)
                    : const Color(0xFFF59E0B);
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(al['category'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),
                            Text(al['post'],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: mutedColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(al['title'],
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textColor)),
                        const SizedBox(height: 4),
                        Text(al['detail'],
                            style: TextStyle(
                                fontSize: 12, color: mutedColor, height: 1.4)),
                      ],
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }

  Widget _buildCustodyView(
      bool dark,
      List<Report> reports,
      List<Claim> claims,
      Color cardColor,
      Color textColor,
      Color mutedColor,
      Color borderColor) {
    final filtered = reports.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.name.toLowerCase().contains(_searchQuery) ||
          r.id.toLowerCase().contains(_searchQuery) ||
          r.pos.toLowerCase().contains(_searchQuery) ||
          r.owner.toLowerCase().contains(_searchQuery);
    }).toList();

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('satpam_officers')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, officerSnap) {
        final officerDocs = officerSnap.data?.docs ?? [];
        final officersByPos = <String, List<Map<String, dynamic>>>{};
        for (final doc in officerDocs) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = doc.id;
          final posKey = (data['post'] as String?) ?? '';
          if (posKey.isNotEmpty) {
            officersByPos.putIfAbsent(posKey, () => []).add(data);
          }
        }

        final allPosts = _allPosList;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Status Penjagaan & Penyimpanan per Pos Satpam (Real-Time)',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  const SizedBox(height: 3),
                  Text(
                      'Otomatis menyorot petugas yang sedang bertugas sesuai jam shift saat ini beserta jumlah barang di setiap pos',
                      style: TextStyle(fontSize: 12, color: mutedColor)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: allPosts.map((posName) {
                      final guardsHere = officersByPos[posName] ?? [];
                      final itemsHere = reports
                          .where((r) => r.pos == posName && r.status != stDone)
                          .length;
                      final hasGuard = guardsHere.isNotEmpty;
                      final onDutyHere = guardsHere
                          .where((g) =>
                              isShiftActiveNow((g['shift'] as String?) ?? ''))
                          .toList();

                      return Container(
                        width: 295,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF16253D)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: onDutyHere.isNotEmpty
                                ? _kToskaMain.withValues(alpha: 0.65)
                                : (hasGuard
                                    ? _kToskaMain.withValues(alpha: 0.3)
                                    : borderColor),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 17,
                                    color: dark ? _kSkyAccent : _kToskaMain),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    posName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: textColor),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: _kToskaMain.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$itemsHere Barang',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: dark ? _kSkyAccent : _kNavyMain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (!hasGuard)
                              Text(
                                '⚠️ Belum ada petugas aktif dijadwalkan',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600),
                              )
                            else
                              for (final g in guardsHere)
                                Builder(builder: (context) {
                                  final shiftStr =
                                      (g['shift'] as String?) ?? 'Shift Reguler';
                                  final activeNow = isShiftActiveNow(shiftStr);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      activeNow
                                          ? '🟢 ${g['name']} (${g['id']}) • $shiftStr (Bertugas Sekarang)'
                                          : '⚪ ${g['name']} (${g['id']}) • $shiftStr',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: activeNow
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: activeNow
                                            ? (dark ? _kSkyAccent : _kToskaMain)
                                            : mutedColor,
                                      ),
                                    ),
                                  );
                                }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
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
                        Text('Daftar Custody Barang & Petugas Penanggung Jawab',
                            style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: textColor)),
                        const SizedBox(height: 3),
                        Text(
                            'Klik "Audit Custody" pada tiap baris untuk melihat detail riwayat serah terima & penjaga pos',
                            style: TextStyle(fontSize: 12, color: mutedColor)),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('Tidak ada data laporan barang.',
                            style: TextStyle(fontSize: 13, color: mutedColor)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: borderColor),
                      itemBuilder: (context, i) {
                        final r = filtered[i];
                        final guardsHere = officersByPos[r.pos] ?? [];
                        final onDuty = guardsHere
                            .where((g) => isShiftActiveNow(
                                (g['shift'] as String?) ?? ''))
                            .firstOrNull;
                        final displayGuard = onDuty ?? guardsHere.firstOrNull;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _kToskaMain.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(r.icon,
                                    color: dark ? _kSkyAccent : _kToskaMain),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${r.name} (${r.id})',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: textColor),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusChip(r.status),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '📍 ${r.pos} • ${displayGuard != null ? "Penjaga: ${displayGuard['name']} (${onDuty != null ? 'Shift Aktif' : displayGuard['shift']})" : "Belum ada petugas terjadwal"}',
                                      style: TextStyle(
                                          fontSize: 11.5, color: mutedColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openItemAuditModal(r, guardsHere),
                                icon: const Icon(Icons.fact_check_outlined,
                                    size: 16),
                                label: const Text('Audit Custody',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfficersView(
      bool dark,
      Color cardColor,
      Color inputFillColor,
      Color textColor,
      Color mutedColor,
      Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Titik Pos Layanan Satpam Kampus UNESA',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
              const SizedBox(height: 3),
              Text(
                  'Tambah titik pos baru yang akan langsung muncul di pilihan form laporan mahasiswa & penugasan petugas',
                  style: TextStyle(fontSize: 12, color: mutedColor)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _newPosC,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Nama Pos Baru',
                        hintText: 'Contoh: Pos Satpam FIK / Lidah',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _newPosAreaC,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Area',
                        hintText: 'Contoh: Kampus Lidah Wetan',
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kNavyMain,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addCampusPos,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('Tambah Pos',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('campus_posts').snapshots(),
                builder: (context, posSnap) {
                  final customDocs = posSnap.data?.docs ?? [];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final basePos in posList)
                        Chip(
                          avatar: const Icon(Icons.verified_rounded,
                              size: 16, color: _kToskaMain),
                          label: Text(basePos,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textColor)),
                          backgroundColor: inputFillColor,
                        ),
                      for (final doc in customDocs)
                        Builder(builder: (context) {
                          final d = doc.data() as Map<String, dynamic>;
                          final name = (d['name'] as String?) ?? doc.id;
                          return InputChip(
                            avatar: const Icon(Icons.location_on_rounded,
                                size: 16, color: _kToskaMain),
                            label: Text(name,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
                            backgroundColor: inputFillColor,
                            onDeleted: () => _deleteCampusPos(doc.id, name),
                            deleteIconColor: Colors.redAccent,
                          );
                        }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
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
                Text('Daftarkan Akun & Jadwal Shift Petugas Satpam',
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
                const SizedBox(height: 3),
                Text(
                    'Sistem otomatis menyesuaikan petugas jaga di seluruh aplikasi berdasarkan jam shift yang diatur di sini',
                    style: TextStyle(fontSize: 12, color: mutedColor)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 190,
                      child: TextFormField(
                        controller: _satpamIdC,
                        style: TextStyle(color: textColor, fontSize: 13),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'ID wajib diisi'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'ID Satpam',
                          hintText: 'Contoh: STP-014',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextFormField(
                        controller: _satpamNameC,
                        style: TextStyle(color: textColor, fontSize: 13),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap Petugas',
                          hintText: 'Contoh: Pak Hendra Wijaya',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        initialValue: _satpamPos ?? _allPosList.first,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor, fontSize: 13),
                        items: _allPosList
                            .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p,
                                    style: TextStyle(color: textColor))))
                            .toList(),
                        onChanged: (v) => setState(() => _satpamPos = v),
                        decoration:
                            const InputDecoration(labelText: 'Pos Jaga'),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextFormField(
                        controller: _satpamShiftC,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Jam Shift',
                          hintText: 'Shift Pagi (07.00 - 14.00 WIB)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Preset Cepat:',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: mutedColor)),
                    ..._shiftPresets.map((preset) {
                      final selected = _selectedShiftPreset == preset;
                      return ChoiceChip(
                        label: Text(
                          preset.split(' (').first,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : textColor,
                          ),
                        ),
                        selected: selected,
                        selectedColor: _kToskaMain,
                        onSelected: (_) {
                          setState(() {
                            _selectedShiftPreset = preset;
                            _satpamShiftC.text = preset;
                          });
                        },
                      );
                    }),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kToskaMain,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _addSatpamOfficer,
                      icon: const Icon(Icons.person_add_alt_1_rounded,
                          size: 18),
                      label: const Text('Simpan & Aktifkan Petugas',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
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
                    Text('Daftar Petugas Satpam & Status Shift Saat Ini',
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                    const SizedBox(height: 3),
                    Text(
                        'Badge hijau menandakan petugas sedang berada di jam shift aktif saat ini',
                        style: TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('satpam_officers').snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final docs = (snap.data?.docs ?? []).where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final d = doc.data() as Map<String, dynamic>;
                    final hay =
                        '${doc.id} ${d['name']} ${d['post']} ${d['shift']}'
                            .toLowerCase();
                    return hay.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('Belum ada data petugas satpam terdaftar.',
                            style: TextStyle(fontSize: 13, color: mutedColor)),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: borderColor),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
                      final id = doc.id;
                      final name = (data['name'] as String?) ?? id;
                      final post = (data['post'] as String?) ?? '-';
                      final shift =
                          (data['shift'] as String?) ?? 'Shift Reguler';
                      final active = (data['active'] as bool?) ?? true;
                      final onDutyNow = active && isShiftActiveNow(shift);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: (onDutyNow
                                            ? _kToskaMain
                                            : (active
                                                ? _kNavyMain
                                                : Colors.grey))
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.shield_rounded,
                                    color: onDutyNow
                                        ? _kToskaMain
                                        : (active
                                            ? (dark
                                                ? _kSkyAccent
                                                : _kNavyMain)
                                            : Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$name ($id)',
                                            style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: textColor)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: onDutyNow
                                                ? _kToskaMain
                                                : (active
                                                    ? Colors.blueGrey
                                                        .withValues(alpha: 0.16)
                                                    : Colors.redAccent
                                                        .withValues(
                                                            alpha: 0.15)),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            onDutyNow
                                                ? '● SEDANG BERTUGAS'
                                                : (active
                                                    ? 'TERJADWAL'
                                                    : 'NONAKTIF'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: onDutyNow
                                                  ? Colors.white
                                                  : (active
                                                      ? textColor
                                                      : Colors.redAccent),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text('$post • $shift',
                                        style: TextStyle(
                                            fontSize: 12, color: mutedColor)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openEditOfficerShiftDialog(
                                    id,
                                    data,
                                    cardColor,
                                    textColor,
                                    mutedColor,
                                    borderColor,
                                  ),
                                  icon: const Icon(Icons.edit_calendar_rounded,
                                      size: 16),
                                  label: const Text('Atur Pos & Shift',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: () =>
                                      _toggleSatpamActive(id, active, name),
                                  child: Text(
                                    active ? 'Nonaktifkan' : 'Aktifkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? Colors.redAccent
                                          : _kToskaMain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsView(bool dark, Color cardColor, Color textColor,
      Color mutedColor, Color borderColor) {
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
                Text('Moderasi Akun Mahasiswa UNESA',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
                const SizedBox(height: 3),
                Text(
                    'Bekukan sementara akun mahasiswa yang terbukti melakukan spam laporan atau klaim palsu berulang',
                    style: TextStyle(fontSize: 12, color: mutedColor)),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = (snap.data?.docs ?? []).where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final role = (d['role'] as String?) ?? 'student';
                if (role == 'admin' || role == 'satpam') return false;
                if (_searchQuery.isEmpty) return true;
                final hay = '${d['name']} ${d['email']} ${d['nim']}'
                    .toLowerCase();
                return hay.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('Belum ada data akun mahasiswa terdaftar.',
                        style: TextStyle(fontSize: 13, color: mutedColor)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: borderColor),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  final name = (d['name'] as String?) ?? 'Mahasiswa UNESA';
                  final email = (d['email'] as String?) ?? doc.id;
                  final nim = (d['nim'] as String?) ?? '-';
                  final blocked = (d['blocked'] as bool?) ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (blocked
                                  ? Colors.redAccent
                                  : _kToskaMain)
                              .withValues(alpha: 0.14),
                          child: Icon(
                            blocked
                                ? Icons.block_rounded
                                : Icons.school_rounded,
                            color: blocked ? Colors.redAccent : _kToskaMain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$name (NIM: $nim)',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: textColor)),
                              Text(
                                  '$email • Status: ${blocked ? "DIBEKUKAN" : "Aktif"}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: blocked
                                          ? Colors.redAccent
                                          : mutedColor)),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () =>
                              _toggleStudentBlock(doc.id, blocked, email),
                          child: Text(
                            blocked ? 'Buka Blokir' : 'Bekukan Akun',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: blocked ? _kToskaMain : Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildAnalyticsView(List<Report> reports, Color cardColor,
      Color textColor, Color mutedColor, Color borderColor) {
    final total = reports.length;
    final foundCount =
        reports.where((r) => r.type == ReportType.ditemukan).length;
    final lostCount = reports.where((r) => r.type == ReportType.hilang).length;
    final doneCount = reports.where((r) => r.status == stDone).length;
    final rate = total == 0 ? 0 : ((doneCount / total) * 100).round();

    final byCategory = <String, int>{};
    for (final r in reports) {
      byCategory[r.categoryLabel] = (byCategory[r.categoryLabel] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analis & Statistik Keamanan Barang Kampus UNESA',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 3),
          Text(
              'Ringkasan rasio penyelesaian laporan serta sebaran kategori barang hilang & temuan',
              style: TextStyle(fontSize: 12, color: mutedColor)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _statBox('Tingkat Pengembalian', '$rate%',
                  '$doneCount dari $total laporan selesai', _kToskaMain),
              _statBox('Laporan Temuan', '$foundCount',
                  'Diserahkan ke pos satpam', _kNavyMain),
              _statBox('Laporan Kehilangan', '$lostCount',
                  'Dilaporkan mahasiswa', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 22),
          Text('Sebaran per Kategori Barang',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 12),
          if (byCategory.isEmpty)
            Text('Belum ada data kategori laporan.',
                style: TextStyle(fontSize: 12.5, color: mutedColor))
          else
            for (final entry in byCategory.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textColor)),
                        Text('${entry.value} barang',
                            style: TextStyle(fontSize: 12, color: mutedColor)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : entry.value / total,
                        minHeight: 8,
                        color: _kToskaMain,
                        backgroundColor: borderColor,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String big, String sub, Color accent) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 4),
          Text(big,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}


