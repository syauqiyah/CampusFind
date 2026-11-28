import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Palet Warna Utama CampusFind UNESA
const kNavyPrimary = Color(0xFF0B2058); // Biru Utama UNESA (Satpam / Institusi)
const kToska = Color(0xFF1080A6);       // Toska Utama (Mahasiswa / Aksi Utama)
const kMintSoft = Color(0xFFE5F7F5);    // Hijau Muda / Mint lembut
const kGreen = kToska;                  // Alias agar kompatibel dengan file lama
const kDeep = Color(0xFF09111E);        // Deep Midnight Navy (Mode Gelap)
const kLeaf = Color(0xFFF1F5F9);        // Abu Muda Bersih (Mode Terang)

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color cardC(BuildContext c) => isDark(c) ? const Color(0xFF111D30) : Colors.white;
Color borderC(BuildContext c) => isDark(c) ? const Color(0xFF1E3250) : const Color(0xFFDCE6F2);
Color mutedC(BuildContext c) => isDark(c) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
Color softC(BuildContext c) => isDark(c) ? const Color(0xFF162740) : const Color(0xFFF1F5F9);
Color onSky(BuildContext c) => Colors.white;
const skyShadow = [
  Shadow(color: Color(0xDD000000), blurRadius: 8, offset: Offset(0, 2)),
  Shadow(color: Color(0xAA000000), blurRadius: 4, offset: Offset(0, 1)),
];

// ------------------------------------------------------------ pilihan form
const categories = ['Dompet', 'Elektronik', 'Tas', 'Kunci', 'Pakaian', 'Dokumen/Kartu', 'Alat Tulis', 'Lainnya'];
const catIcons = {
  'Dompet': Icons.account_balance_wallet_outlined,
  'Elektronik': Icons.smartphone_outlined,
  'Tas': Icons.backpack_outlined,
  'Kunci': Icons.key_outlined,
  'Pakaian': Icons.checkroom_outlined,
  'Dokumen/Kartu': Icons.badge_outlined,
  'Alat Tulis': Icons.edit_outlined,
  'Lainnya': Icons.inventory_2_outlined,
};
const areas = [
  'Perpustakaan',
  'Gedung Rektorat',
  'Gedung Fakultas',
  'Ruang Kelas / Laboratorium',
  'Kantin',
  'Masjid / Mushola',
  'Lapangan / Gedung Olahraga',
  'Area Parkir',
  'Taman / Area Terbuka',
  'Gerbang / Jalan Kampus',
  'Lainnya',
];
const defaultPosList = ['Pos Gerbang Depan', 'Pos Gerbang Belakang'];

/// Daftar pos aktif (otomatis terbarui dari Firestore jika Admin menambah unit pos baru).
List<String> get posList => store.availablePosList;

const stWait = 'Menunggu Verifikasi';
const stActive = 'Aktif';
const stClaimed = 'Diklaim';
const stDone = 'Selesai';
const stRejected = 'Ditolak';

const _bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
String fmtDate(DateTime d) => '${d.day} ${_bln[d.month - 1]} ${d.year}';
String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  return '${d.inDays} hari lalu';
}

/// Menentukan nama shift aktif default berdasarkan jam saat ini.
String currentShiftLabel([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h >= 7 && h < 14) return 'Shift Pagi (07.00 - 14.00 WIB)';
  if (h >= 14 && h < 21) return 'Shift Sore (14.00 - 21.00 WIB)';
  return 'Shift Malam (21.00 - 07.00 WIB)';
}

/// Mengecek apakah jam sekarang masuk ke rentang shift (mis. "Shift Pagi (07.00 - 14.00 WIB)" atau "21.00 - 07.00").
bool isShiftActiveNow(String shiftText, [DateTime? now]) {
  final t = now ?? DateTime.now();
  final nowMinutes = t.hour * 60 + t.minute;

  final m = RegExp(r'(\d{1,2})[:.](\d{2})\s*[-–—]\s*(\d{1,2})[:.](\d{2})')
      .firstMatch(shiftText);
  if (m != null) {
    final start = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    final end = int.parse(m.group(3)!) * 60 + int.parse(m.group(4)!);
    if (start == end) return true;
    if (start < end) {
      return nowMinutes >= start && nowMinutes < end;
    } else {
      // Shift lintas tengah malam, misal 21.00 - 07.00
      return nowMinutes >= start || nowMinutes < end;
    }
  }

  final lower = shiftText.toLowerCase();
  final h = t.hour;
  if (lower.contains('pagi')) return h >= 7 && h < 14;
  if (lower.contains('sore')) return h >= 14 && h < 21;
  if (lower.contains('malam')) return h >= 21 || h < 7;
  return true;
}

// ------------------------------------------------------------------ model
enum ReportType { hilang, ditemukan }

class PosDutyInfo {
  final String posName;
  final String officerName;
  final String shift;
  final DateTime updatedAt;

  const PosDutyInfo({
    required this.posName,
    required this.officerName,
    required this.shift,
    required this.updatedAt,
  });
}

class SatpamOfficer {
  final String id;
  final String name;
  final String post;
  final String shift;
  final bool active;

  const SatpamOfficer({
    required this.id,
    required this.name,
    required this.post,
    required this.shift,
    required this.active,
  });

  factory SatpamOfficer.fromFirestore(Map<String, dynamic> j, String docId) =>
      SatpamOfficer(
        id: (j['id'] as String?)?.trim().isNotEmpty == true
            ? (j['id'] as String).trim()
            : docId,
        name: (j['name'] as String?)?.trim() ?? 'Petugas Pos',
        post: (j['post'] as String?)?.trim() ?? defaultPosList[0],
        shift: (j['shift'] as String?)?.trim() ?? currentShiftLabel(),
        active: (j['active'] as bool?) ?? true,
      );
}

class Report {
  final String id, name, category, categoryCustom, description, secret, area, areaDetail, pos, owner;
  final ReportType type;
  final DateTime date;
  final String? photo;
  String status;
  String token;
  DateTime? tokenExp;
  String verifiedBy;

  Report({
    required this.id,
    required this.type,
    required this.name,
    required this.category,
    this.categoryCustom = '',
    required this.description,
    required this.secret,
    required this.area,
    required this.areaDetail,
    required this.pos,
    required this.owner,
    required this.date,
    this.photo,
    this.status = stActive,
    this.token = '',
    this.tokenExp,
    this.verifiedBy = '',
  });

  String get typeLabel => type == ReportType.hilang ? 'Hilang' : 'Ditemukan';
  String get categoryLabel => category == 'Lainnya' && categoryCustom.isNotEmpty ? categoryCustom : category;
  IconData get icon => catIcons[category] ?? Icons.inventory_2_outlined;
  bool get isPublic => status == stActive || status == stClaimed;

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'typeIndex': type.index,
    'type': typeLabel,
    'title': name,
    'name': name,
    'category': category,
    'cc': categoryCustom,
    'desc': description,
    'secretDetail': secret,
    'secret': secret,
    'area': area,
    'ad': areaDetail,
    'pos': pos,
    'reporterEmail': owner,
    'owner': owner,
    'date': date.toIso8601String(),
    'photo': photo,
    'status': status,
    'token': token,
    'exp': tokenExp?.toIso8601String(),
    'verifiedBy': verifiedBy,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory Report.fromFirestore(Map<String, dynamic> j, String docId) {
    final typeIdx = j['typeIndex'] is int
        ? j['typeIndex'] as int
        : ((j['type'] == 'Hilang') ? 0 : 1);
    return Report(
      id: (j['id'] as String?) ?? docId,
      type: ReportType.values[typeIdx.clamp(0, 1)],
      name: (j['name'] ?? j['title'] ?? 'Tanpa Nama') as String,
      category: (j['category'] ?? 'Lainnya') as String,
      categoryCustom: (j['cc'] ?? '') as String,
      description: (j['desc'] ?? '') as String,
      secret: (j['secret'] ?? j['secretDetail'] ?? '') as String,
      area: (j['area'] ?? 'Lainnya') as String,
      areaDetail: (j['ad'] ?? '') as String,
      pos: (j['pos'] ?? defaultPosList[0]) as String,
      owner: (j['owner'] ?? j['reporterEmail'] ?? '') as String,
      date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) ?? DateTime.now() : DateTime.now(),
      photo: j['photo'] as String?,
      status: (j['status'] ?? stWait) as String,
      token: (j['token'] ?? '') as String,
      tokenExp: j['exp'] == null ? null : DateTime.tryParse(j['exp'].toString()),
      verifiedBy: (j['verifiedBy'] ?? '') as String,
    );
  }
}

class Claim {
  final String id, reportId, claimer, answer, proof;
  final String? photo;
  final DateTime date;
  String status;
  String token;
  DateTime? tokenExp;
  String claimerNim;
  String handedOverBy;

  Claim({
    required this.id,
    required this.reportId,
    required this.claimer,
    required this.answer,
    this.proof = '',
    this.photo,
    required this.date,
    this.status = 'Menunggu',
    this.token = '',
    this.tokenExp,
    this.claimerNim = '',
    this.handedOverBy = '',
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'rid': reportId,
    'claimer': claimer,
    'answer': answer,
    'proof': proof,
    'photo': photo,
    'date': date.toIso8601String(),
    'status': status,
    'token': token,
    'exp': tokenExp?.toIso8601String(),
    'claimerNim': claimerNim,
    'handedOverBy': handedOverBy,
  };

  factory Claim.fromFirestore(Map<String, dynamic> j, String docId) => Claim(
    id: (j['id'] as String?) ?? docId,
    reportId: (j['rid'] ?? '') as String,
    claimer: (j['claimer'] ?? '') as String,
    answer: (j['answer'] ?? '') as String,
    proof: (j['proof'] ?? '') as String,
    photo: j['photo'] as String?,
    date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) ?? DateTime.now() : DateTime.now(),
    status: (j['status'] ?? 'Menunggu') as String,
    token: (j['token'] ?? '') as String,
    tokenExp: j['exp'] == null ? null : DateTime.tryParse(j['exp'].toString()),
    claimerNim: (j['claimerNim'] ?? '') as String,
    handedOverBy: (j['handedOverBy'] ?? '') as String,
  );
}

class AppNotif {
  final String id, owner, type, title, message;
  final DateTime time;
  bool read;
  final String? reportId;
  final List<String> matchIds;
  final List<double> scores;

  AppNotif({
    required this.id,
    required this.owner,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
    this.reportId,
    this.matchIds = const [],
    this.scores = const [],
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'owner': owner,
    'type': type,
    'title': title,
    'message': message,
    'time': time.toIso8601String(),
    'read': read,
    'rid': reportId,
    'mids': matchIds,
    'scores': scores,
  };

  factory AppNotif.fromFirestore(Map<String, dynamic> j, String docId) => AppNotif(
    id: (j['id'] as String?) ?? docId,
    owner: (j['owner'] ?? '') as String,
    type: (j['type'] ?? 'info') as String,
    title: (j['title'] ?? '') as String,
    message: (j['message'] ?? '') as String,
    time: j['time'] != null ? DateTime.tryParse(j['time'].toString()) ?? DateTime.now() : DateTime.now(),
    read: (j['read'] ?? false) as bool,
    reportId: j['rid'] as String?,
    matchIds: List<String>.from(j['mids'] ?? []),
    scores: (j['scores'] as List? ?? []).map((e) => (e as num).toDouble()).toList(),
  );
}

// ---------------------------------------------------- pencocokan "AI"
const _stop = {'dan', 'yang', 'di', 'ke', 'dari', 'dengan', 'ada', 'warna', 'berwarna', 'yg', 'dgn', 'sebuah', 'satu', 'kecil', 'besar', 'ukuran'};
Set<String> _tok(String s) => s.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((w) => w.length > 2 && !_stop.contains(w)).toSet();
double _jac(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  return a.intersection(b).length / a.union(b).length;
}

double matchScore(Report lost, Report found) {
  var s = 0.0;
  if (lost.category == found.category) {
    s += 0.20;
    if (lost.category == 'Lainnya') s += 0.05 * _jac(_tok(lost.categoryCustom), _tok(found.categoryCustom));
  }
  s += 0.35 * min(1.0, _jac(_tok(lost.name), _tok(found.name)) * 1.6);
  s += 0.20 * min(1.0, _jac(_tok('${lost.description} ${lost.secret}'), _tok('${found.description} ${found.secret}')) * 2.0);
  if (lost.area == found.area) s += 0.15;
  final d = found.date.difference(lost.date).inDays;
  if (d >= -1 && d <= 14) s += 0.10 * (1 - d.abs() / 15);
  return min(1.0, s);
}

const matchThreshold = 0.5;

// ------------------------------------------------------------------ model pengguna
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String nim;
  final String role;
  final String postName;
  final String photoUrl;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.nim = '',
    required this.role,
    this.postName = '',
    this.photoUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'nim': nim,
    'role': role,
    'postName': postName,
    'photoUrl': photoUrl,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: (json['uid'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    nim: (json['nim'] ?? '') as String,
    role: (json['role'] ?? '') as String,
    postName: (json['postName'] ?? '') as String,
    photoUrl: (json['photoUrl'] ?? '') as String,
  );
}

typedef AppStore = Store;

// ------------------------------------------------------------------ store (Firestore Real-time)
class Store extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _rnd = Random.secure();

  AppUser? currentUser;
  bool get isLoggedIn => currentUser != null;

  String email = '';
  String customName = '';
  bool guard = false;
  String guardId = '';
  String guardPos = defaultPosList[0];

  List<String> customPosUnits = [];
  List<String> get availablePosList {
    final merged = <String>[...defaultPosList];
    for (final p in customPosUnits) {
      if (p.trim().isNotEmpty && !merged.any((m) => m.toLowerCase() == p.trim().toLowerCase())) {
        merged.add(p.trim());
      }
    }
    return merged;
  }

  final Map<String, PosDutyInfo> posDuties = {};
  List<SatpamOfficer> officers = [];

  List<Report> reports = [];
  List<Claim> claims = [];
  List<AppNotif> notifs = [];
  AppNotif? lastNotif;

  final Map<String, ({String token, DateTime exp})> _livePosTokens = {};

  StreamSubscription? _repSub;
  StreamSubscription? _claimSub;
  StreamSubscription? _notifSub;
  StreamSubscription? _posTokenSub;
  StreamSubscription? _campusPostSub;
  StreamSubscription? _officerSub;

  String get _nameStorageKey => 'custom_name_${guard ? "guard" : (email.isNotEmpty ? email : "user")}';

  String get name {
    if (customName.trim().isNotEmpty) return customName.trim();
    if (currentUser?.name.isNotEmpty == true) return currentUser!.name.trim();
    if (guard) return 'Petugas Pos';
    final raw = email.split('@').first.replaceAll(RegExp(r'[._\-\d]+'), ' ').trim();
    if (raw.isEmpty) return 'Warga UNESA';
    return raw.split(' ').where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
  }

  /// Mengambil petugas yang SEDANG BERTUGAS sekarang di [pos] berdasarkan jadwal Admin & jam saat ini.
  SatpamOfficer? activeOfficerForPos(String pos, [DateTime? now]) {
    final clean = pos.trim().toLowerCase();
    final atPos = officers
        .where((o) => o.active && o.post.trim().toLowerCase() == clean)
        .toList();
    if (atPos.isEmpty) return null;

    for (final o in atPos) {
      if (isShiftActiveNow(o.shift, now)) return o;
    }
    return atPos.first;
  }

  /// Semua petugas aktif yang terdaftar di [pos] (lintas shift).
  List<SatpamOfficer> officersAtPos(String pos) {
    final clean = pos.trim().toLowerCase();
    return officers
        .where((o) => o.active && o.post.trim().toLowerCase() == clean)
        .toList();
  }

  /// Data satpam yang sedang login dari koleksi satpam_officers.
  SatpamOfficer? get currentGuardOfficer {
    if (!guard) return null;
    final cleanId = guardId.trim().toUpperCase();
    if (cleanId.isNotEmpty) {
      for (final o in officers) {
        if (o.id.toUpperCase() == cleanId) return o;
      }
    }
    for (final o in officers) {
      if (o.name.toLowerCase() == name.toLowerCase()) return o;
    }
    return null;
  }

  PosDutyInfo? dutyForPos(String pos) {
    final active = activeOfficerForPos(pos);
    if (active != null) {
      return PosDutyInfo(
        posName: active.post,
        officerName: active.name,
        shift: active.shift,
        updatedAt: DateTime.now(),
      );
    }
    return posDuties[pos.trim()];
  }

  void _syncLoggedInGuardAssignment() {
    if (!guard) return;
    final me = currentGuardOfficer;
    if (me != null) {
      final posChanged = guardPos != me.post;
      guardPos = me.post;
      if (me.name.isNotEmpty) customName = me.name;
      if (posChanged) {
        issuePosToken(guardPos);
      }
    }
  }

  Future<void> login({
    required String uid,
    required String name,
    required String email,
    String nim = '',
    required String role,
    String postName = '',
    String photoUrl = '',
  }) async {
    final user = AppUser(
      uid: uid,
      name: name,
      email: email,
      nim: nim,
      role: role,
      postName: postName,
      photoUrl: photoUrl,
    );
    await saveSession(user);
  }

  Future<void> saveSession(AppUser user) async {
    currentUser = user;
    guard = (user.role == 'satpam' || user.role == 'guard');
    email = user.email;
    if (guard) {
      guardId = user.uid.trim().toUpperCase();
    }
    if (user.name.isNotEmpty) customName = user.name;
    if (guard && user.postName.isNotEmpty) guardPos = user.postName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_uid', user.uid);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_nim', user.nim);
    await prefs.setString('user_role', user.role);
    await prefs.setString('user_post_name', user.postName);
    await prefs.setString('user_photo_url', user.photoUrl);

    if (guard) {
      await prefs.setString('guard_id', guardId);
      await prefs.setString('guard_pos', guardPos);
      _syncLoggedInGuardAssignment();
      await issuePosToken(guardPos);
    }

    notifyListeners();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedInPref = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedInPref) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final savedUid = prefs.getString('user_uid') ?? '';
      final savedEmail = prefs.getString('user_email') ?? '';

      final finalUid = (firebaseUser?.uid != null && firebaseUser!.uid.isNotEmpty)
          ? firebaseUser.uid
          : savedUid;
      final finalEmail = (firebaseUser?.email != null && firebaseUser!.email!.isNotEmpty)
          ? firebaseUser.email!
          : savedEmail;

      final savedName = prefs.getString('user_name') ?? '';
      final savedNim = prefs.getString('user_nim') ?? '';
      final savedRole = prefs.getString('user_role') ?? (guard ? 'satpam' : 'mahasiswa');
      final savedPostName = prefs.getString('user_post_name') ?? guardPos;
      final savedPhotoUrl = prefs.getString('user_photo_url') ?? firebaseUser?.photoURL ?? '';

      currentUser = AppUser(
        uid: finalUid,
        name: savedName,
        email: finalEmail,
        nim: savedNim,
        role: savedRole,
        postName: savedPostName,
        photoUrl: savedPhotoUrl,
      );

      guard = (savedRole == 'satpam' || savedRole == 'guard');
      if (guard) {
        guardId = (prefs.getString('guard_id') ?? finalUid).trim().toUpperCase();
      }
      email = finalEmail;
      if (savedName.isNotEmpty) customName = savedName;
      if (guard && savedPostName.isNotEmpty) guardPos = savedPostName;
    } else {
      currentUser = null;
    }
    notifyListeners();
  }

  Future<void> updateName(String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    customName = clean;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameStorageKey, clean);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !guard) {
      await _db.collection('users').doc(uid).set({
        'name': clean,
        'email': email,
      }, SetOptions(merge: true));
    } else if (guard && guardId.isNotEmpty) {
      await _db.collection('satpam_officers').doc(guardId).set({
        'name': clean,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ---------------------------------------------- Manajemen Pos (Kompatibilitas Lama)
  Future<String?> addPosUnit(String posName) async {
    final clean = posName.trim();
    if (clean.isEmpty) return 'Nama pos tidak boleh kosong.';
    if (availablePosList.any((p) => p.toLowerCase() == clean.toLowerCase())) {
      return 'Pos "$clean" sudah terdaftar.';
    }

    customPosUnits.add(clean);
    notifyListeners();

    try {
      await _db.collection('campus_posts').doc(_posDocId(clean)).set({
        'name': clean,
        'area': 'Area Kampus UNESA',
        'active': true,
        'createdBy': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Gagal menambahkan pos ke server: $e';
    }
  }

  Future<void> deletePosUnit(String posName) async {
    final clean = posName.trim();
    if (defaultPosList.contains(clean)) return;
    customPosUnits.removeWhere((p) => p == clean);
    if (guardPos == clean) {
      guardPos = defaultPosList.first;
    }
    notifyListeners();
    try {
      await _db.collection('campus_posts').doc(_posDocId(clean)).delete();
    } catch (_) {}
  }

  Future<void> takeOverShift(String posName) async {
    final cleanPos = posName.trim();
    guardPos = cleanPos;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_post_name', cleanPos);
    notifyListeners();
    await issuePosToken(cleanPos);
  }

  String nextReportId() => 'CF-${1000 + _rnd.nextInt(9000)}';
  String nextClaimId() => 'CL-${1000 + _rnd.nextInt(9000)}';

  // -------------------------------------------------- muat & dengarkan Firestore
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('cf_data_v3');
    final savedCustomName = p.getString(_nameStorageKey) ?? '';
    if (savedCustomName.isNotEmpty) customName = savedCustomName;

    await _repSub?.cancel();
    await _claimSub?.cancel();
    await _notifSub?.cancel();
    await _posTokenSub?.cancel();
    await _campusPostSub?.cancel();
    await _officerSub?.cancel();

    // 1. Dengarkan daftar pos tambahan dari Admin (campus_posts)
    _campusPostSub = _db.collection('campus_posts').snapshots().listen((snap) {
      final units = <String>[];
      for (final d in snap.docs) {
        final data = d.data();
        final active = (data['active'] as bool?) ?? true;
        final posName = (data['name'] as String?)?.trim() ?? '';
        if (active && posName.isNotEmpty && !defaultPosList.contains(posName)) {
          units.add(posName);
        }
      }
      customPosUnits = units;
      notifyListeners();
    });

    // 2. Dengarkan jadwal & penugasan satpam dari Admin (satpam_officers)
    _officerSub = _db.collection('satpam_officers').snapshots().listen((snap) {
      officers = snap.docs
          .map((d) => SatpamOfficer.fromFirestore(d.data(), d.id))
          .toList();

      posDuties.clear();
      for (final pos in availablePosList) {
        final activeOfficer = activeOfficerForPos(pos);
        if (activeOfficer != null) {
          posDuties[pos] = PosDutyInfo(
            posName: pos,
            officerName: activeOfficer.name,
            shift: activeOfficer.shift,
            updatedAt: DateTime.now(),
          );
        }
      }
      _syncLoggedInGuardAssignment();
      notifyListeners();
    });

    _repSub = _db.collection('reports').snapshots().listen((snap) {
      final list = snap.docs
          .map((d) => Report.fromFirestore(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      reports = list;
      notifyListeners();
    });

    _claimSub = _db.collection('claims').snapshots().listen((snap) {
      final list = snap.docs
          .map((d) => Claim.fromFirestore(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      claims = list;
      notifyListeners();
    });

    _notifSub = _db.collection('notifs').snapshots().listen((snap) {
      final list = snap.docs
          .map((d) => AppNotif.fromFirestore(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.time.compareTo(a.time));
      notifs = list;
      notifyListeners();
    });

    _posTokenSub = _db.collection('pos_tokens').snapshots().listen((snap) {
      for (final d in snap.docs) {
        final data = d.data();
        final pos = (data['pos'] as String?) ?? d.id;
        final tok = (data['token'] as String?) ?? '';
        final exp = data['exp'] != null ? DateTime.tryParse(data['exp'].toString()) : null;
        if (tok.isNotEmpty && exp != null) {
          _livePosTokens[pos] = (token: tok, exp: exp);
          if (pos == guardPos) {
            posToken = tok;
            posTokenExp = exp;
            posTokenPos = pos;
            posSynced = true;
            posSyncError = null;
          }
        }
      }
      notifyListeners();
    });

    final uid = FirebaseAuth.instance.currentUser?.uid ?? currentUser?.uid;
    if (uid != null && uid.isNotEmpty && !guard) {
      try {
        final doc = await _db.collection('users').doc(uid).get();
        final data = doc.data();
        final savedName = data?['name'] as String?;
        final savedNim = data?['nim'] as String?;
        final savedPhotoUrl = data?['photoUrl'] as String?;
        if (savedName != null && savedName.trim().isNotEmpty) {
          customName = savedName.trim();
          await p.setString(_nameStorageKey, customName);
        }
        if (currentUser != null) {
          currentUser = AppUser(
            uid: currentUser!.uid,
            name: customName.isNotEmpty ? customName : currentUser!.name,
            email: currentUser!.email,
            nim: (savedNim != null && savedNim.isNotEmpty) ? savedNim : currentUser!.nim,
            role: currentUser!.role,
            postName: currentUser!.postName,
            photoUrl: (savedPhotoUrl != null && savedPhotoUrl.isNotEmpty) ? savedPhotoUrl : currentUser!.photoUrl,
          );
          await p.setString('user_name', currentUser!.name);
          await p.setString('user_nim', currentUser!.nim);
          await p.setString('user_photo_url', currentUser!.photoUrl);
        }
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _syncReport(Report r) async {
    await _db.collection('reports').doc(r.id).set(r.toFirestore(), SetOptions(merge: true));
  }

  Future<void> _syncClaim(Claim c) async {
    await _db.collection('claims').doc(c.id).set(c.toFirestore(), SetOptions(merge: true));
  }

  Future<void> _syncNotif(AppNotif n) async {
    await _db.collection('notifs').doc(n.id).set(n.toFirestore(), SetOptions(merge: true));
  }

  // ------------------------------------------------------- pencarian data
  Report? find(String id) {
    for (final r in reports) {
      if (r.id.toLowerCase() == id.trim().toLowerCase()) return r;
    }
    return null;
  }

  Claim? findClaim(String id) {
    for (final c in claims) {
      if (c.id.toLowerCase() == id.trim().toLowerCase()) return c;
    }
    return null;
  }

  List<Claim> claimsOf(String reportId) => claims.where((c) => c.reportId == reportId).toList();

  Claim? pendingClaimOf(String reportId, String who) {
    for (final c in claims) {
      if (c.reportId == reportId && c.claimer == who && c.status == 'Menunggu') return c;
    }
    return null;
  }

  // ---------------------------------------------------------- token QR
  String _newToken() {
    const ch = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(4, (_) => ch[_rnd.nextInt(ch.length)]).join();
  }

  static const tokenLife = Duration(minutes: 5);

  String posToken = '';
  DateTime? posTokenExp;
  String posTokenPos = '';
  String? posSyncError;
  bool posSynced = false;

  String _posDocId(String pos) =>
      pos.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  Future<void> issuePosToken(String pos) async {
    final cleanPos = pos.trim();
    final tok = _newToken();
    final exp = DateTime.now().add(tokenLife);
    posToken = tok;
    posTokenExp = exp;
    posTokenPos = cleanPos;
    posSynced = false;
    posSyncError = null;
    _livePosTokens[cleanPos] = (token: tok, exp: exp);
    notifyListeners();

    try {
      await _db.collection('pos_tokens').doc(_posDocId(cleanPos)).set({
        'pos': cleanPos,
        'token': tok,
        'exp': exp.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      posSynced = true;
      posSyncError = null;
    } catch (e) {
      posSynced = false;
      posSyncError = 'Gagal kirim QR ke server: $e';
      debugPrint(posSyncError);
    }
    notifyListeners();
  }

  bool isPosTokenValid(String pos, String token) {
    final cleanPos = pos.trim();
    final cleanToken = token.trim().toUpperCase();

    final live = _livePosTokens[cleanPos];
    if (live != null && live.token == cleanToken && DateTime.now().isBefore(live.exp)) {
      return true;
    }

    return posToken.isNotEmpty &&
        posToken == cleanToken &&
        (posTokenPos.isEmpty || posTokenPos == cleanPos) &&
        posTokenExp != null &&
        DateTime.now().isBefore(posTokenExp!);
  }

  void issueReportToken(Report r) {
    r.token = _newToken();
    r.tokenExp = DateTime.now().add(tokenLife);
    _syncReport(r);
  }

  void issueClaimToken(Claim c) {
    c.token = _newToken();
    c.tokenExp = DateTime.now().add(tokenLife);
    _syncClaim(c);
  }

  bool tokenOk(String expected, String given, DateTime? exp) =>
      expected.isNotEmpty && expected == given && exp != null && DateTime.now().isBefore(exp);

  (String, String, String)? parse(String raw) {
    final s = raw.trim();
    if (s.startsWith('CF|')) {
      final p = s.split('|');
      if (p.length == 4) return (p[1], p[2], p[3]);
      return null;
    }
    final m = RegExp(r'^(CF|CL)-(\d+)-([A-Za-z0-9]{4})$').firstMatch(s);
    if (m == null) return null;
    return (m.group(1) == 'CF' ? 'R' : 'C', '${m.group(1)}-${m.group(2)}', m.group(3)!.toUpperCase());
  }

  Future<String?> verifyByPosTokenAsync(String kind, String targetId, String posName, String token) async {
    final cleanPos = posName.trim();
    final cleanToken = token.trim().toUpperCase();
    final docId = _posDocId(cleanPos);

    bool valid = false;
    String debugReason = '';

    try {
      final doc = await _db
          .collection('pos_tokens')
          .doc(docId)
          .get(const GetOptions(source: Source.server));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final dbTok = (data['token'] ?? '').toString().trim().toUpperCase();
        final dbExp = data['exp'] != null ? DateTime.tryParse(data['exp'].toString()) : null;

        if (dbTok == cleanToken) {
          if (dbExp == null || DateTime.now().isBefore(dbExp)) {
            valid = true;
          } else {
            debugReason = 'Token QR sudah lewat waktu kedaluwarsa.';
          }
        } else {
          debugReason = 'Kode QR berbeda dengan server (Server: $dbTok, Terbaca: $cleanToken).';
        }
      } else {
        debugReason = 'Dokumen QR Pos ($docId) belum tersimpan di server.';
      }
    } catch (e) {
      debugReason = 'Koneksi Firestore bermasalah: $e';
      valid = isPosTokenValid(cleanPos, cleanToken);
    }

    if (!valid) {
      return debugReason.isNotEmpty
          ? 'QR gagal: $debugReason'
          : 'QR Pos Satpam tidak valid atau sudah kedaluwarsa. Minta Satpam memperbarui QR Pos.';
    }

    if (kind == 'R') {
      final r = find(targetId);
      if (r == null) return 'Laporan tidak ditemukan.';
      if (r.status == stActive) return null;
      if (r.status != stWait) return 'Laporan ini sudah diproses (${r.status}).';
      if (r.pos != cleanPos) return 'Laporan ini harus diverifikasi di ${r.pos}, bukan di $cleanPos.';

      approveReport(r);
      await issuePosToken(cleanPos);
      return null;
    } else {
      final c = findClaim(targetId);
      if (c == null) return 'Klaim tidak ditemukan.';
      if (c.status == 'Disetujui') return null;
      if (c.status != 'Menunggu') return 'Klaim ini sudah diproses (${c.status}).';
      final r = find(c.reportId);
      if (r != null && r.pos != cleanPos) return 'Klaim ini harus diverifikasi di ${r.pos}, bukan di $cleanPos.';

      approveClaim(c);
      await issuePosToken(cleanPos);
      return null;
    }
  }

  // ----------------------------------------------------------- laporan
  void add(Report r) {
    reports.insert(0, r);
    notifyListeners();
    _syncReport(r);
  }

  Future<void> updateReport(Report updated) async {
    final idx = reports.indexWhere((x) => x.id == updated.id);
    if (idx != -1) {
      reports[idx] = updated;
      notifyListeners();
    }
    await _syncReport(updated);
  }

  Future<void> deleteReport(String reportId) async {
    reports.removeWhere((x) => x.id == reportId);
    notifyListeners();
    await _db.collection('reports').doc(reportId).delete();
  }

  void approveReport(Report r) {
    final activeOfficer = activeOfficerForPos(r.pos);
    r.status = stActive;
    r.token = '';
    r.tokenExp = null;
    r.verifiedBy = guard ? name : (activeOfficer?.name ?? 'Petugas Pos');
    notify(
      r.owner,
      'verified',
      'Laporan terverifikasi & diunggah',
      'Laporan "${r.name}" sudah dipindai dan disetujui ${r.verifiedBy} (${r.pos}). Sekarang laporanmu tampil di Beranda.',
      reportId: r.id,
    );
    runMatching(r);
    notifyListeners();
    _syncReport(r);
  }

  void rejectReport(Report r) {
    r.status = stRejected;
    r.token = '';
    r.tokenExp = null;
    notify(
      r.owner,
      'info',
      'Laporan ditolak',
      'Laporan "${r.name}" tidak disetujui satpam. Silakan buat laporan baru dengan data yang benar.',
      reportId: r.id,
    );
    notifyListeners();
    _syncReport(r);
  }

  void complete(Report r) {
    r.status = stDone;
    notifyListeners();
    _syncReport(r);
  }

  // ------------------------------------------------------------- klaim
  void addClaim(Claim c) {
    claims.insert(0, c);
    final r = find(c.reportId);
    if (r != null) {
      r.status = stClaimed;
      _syncReport(r);
      notify(
        r.owner,
        'claim',
        'Ada klaim pada barang temuanmu',
        'Seseorang mengajukan klaim untuk "${r.name}". Satpam akan memverifikasinya.',
        reportId: r.id,
      );
    }
    notifyListeners();
    _syncClaim(c);
  }

  void approveClaim(Claim c, {String claimerNim = ''}) {
    final r = find(c.reportId);
    final activeOfficer = r != null ? activeOfficerForPos(r.pos) : null;
    c.status = 'Disetujui';
    c.token = '';
    c.tokenExp = null;
    if (claimerNim.trim().isNotEmpty) {
      c.claimerNim = claimerNim.trim();
    }
    c.handedOverBy = guard ? name : (activeOfficer?.name ?? 'Petugas Pos');
    _syncClaim(c);

    for (final o in claims.where((x) => x.reportId == c.reportId && x.id != c.id && x.status == 'Menunggu')) {
      o.status = 'Ditolak';
      _syncClaim(o);
      notify(
        o.claimer,
        'claim',
        'Klaim tidak disetujui',
        'Barang "${r?.name ?? ''}" sudah diserahkan kepada pemilik lain yang terverifikasi.',
        reportId: c.reportId,
      );
    }
    if (r != null) {
      r.status = stDone;
      _syncReport(r);
      notify(
        r.owner,
        'info',
        'Barang temuanmu sudah diserahkan',
        '"${r.name}" sudah diserahkan kepada pemilik yang terverifikasi. Terima kasih!',
        reportId: r.id,
      );
    }
    notify(
      c.claimer,
      'claim',
      'Klaim disetujui!',
      'Klaim "${r?.name ?? ''}" disetujui oleh ${c.handedOverBy}. Barang diserahkan di ${r?.pos ?? 'pos satpam'}.',
      reportId: c.reportId,
    );
    notifyListeners();
  }

  void rejectClaim(Claim c) {
    final r = find(c.reportId);
    c.status = 'Ditolak';
    c.token = '';
    c.tokenExp = null;
    _syncClaim(c);

    if (r != null && !claims.any((x) => x.reportId == r.id && x.status == 'Menunggu')) {
      r.status = stActive;
      _syncReport(r);
    }
    notify(
      c.claimer,
      'claim',
      'Klaim ditolak',
      'Detail rahasia pada klaim "${r?.name ?? ''}" tidak cocok dengan laporan. Kamu bisa mencoba lagi dengan data yang benar.',
      reportId: c.reportId,
    );
    notifyListeners();
  }

  // ------------------------------------------------------- notifikasi
  void notify(String owner, String type, String title, String message, {String? reportId, List<String> matchIds = const [], List<double> scores = const []}) {
    final n = AppNotif(
      id: '${DateTime.now().microsecondsSinceEpoch}$type',
      owner: owner,
      type: type,
      title: title,
      message: message,
      time: DateTime.now(),
      reportId: reportId,
      matchIds: matchIds,
      scores: scores,
    );
    notifs.insert(0, n);
    lastNotif = n;
    notifyListeners();
    _syncNotif(n);
  }

  int unread(String who) => notifs.where((n) => n.owner == who && !n.read).length;

  void markRead(AppNotif n) {
    if (n.read) return;
    n.read = true;
    notifyListeners();
    _syncNotif(n);
  }

  void markAllRead(String who) {
    for (final n in notifs.where((n) => n.owner == who)) {
      if (!n.read) {
        n.read = true;
        _syncNotif(n);
      }
    }
    notifyListeners();
  }

  void runMatching(Report r) {
    if (r.type == ReportType.hilang) {
      final c = <(Report, double)>[];
      for (final f in reports) {
        if (f.type == ReportType.ditemukan && f.isPublic) {
          final s = matchScore(r, f);
          if (s >= matchThreshold) c.add((f, s));
        }
      }
      c.sort((a, b) => b.$2.compareTo(a.$2));
      if (c.isNotEmpty) {
        final top = c.take(3).toList();
        notify(
          r.owner,
          'match',
          'Kemungkinan barangmu ditemukan!',
          '${top.length} barang temuan mirip dengan "${r.name}" (kecocokan tertinggi ${(top.first.$2 * 100).round()}%). Ketuk untuk melihat.',
          reportId: r.id,
          matchIds: top.map((e) => e.$1.id).toList(),
          scores: top.map((e) => e.$2).toList(),
        );
      }
    } else {
      for (final l in reports.where((x) => x.type == ReportType.hilang && x.isPublic).toList()) {
        final s = matchScore(l, r);
        if (s >= matchThreshold) {
          notify(
            l.owner,
            'match',
            'Ada barang temuan yang mirip!',
            '"${r.name}" baru saja ditemukan dan cocok ${(s * 100).round()}% dengan laporan hilangmu "${l.name}". Ketuk untuk melihat.',
            reportId: l.id,
            matchIds: [r.id],
            scores: [s],
          );
        }
      }
    }
  }

  Future<void> logout() async {
    email = '';
    customName = '';
    guard = false;
    guardId = '';
    currentUser = null;

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_uid');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_nim');
    await prefs.remove('user_role');
    await prefs.remove('user_post_name');
    await prefs.remove('guard_logged_in');
    await prefs.remove('guard_id');
    await prefs.remove('guard_pos');

    notifyListeners();
  }
}

final store = Store();

// --------------------------------------------------------------- settings
class AppSettings extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;
  double fontScale = 1.0;
  String? avatar;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    mode = (p.getInt('theme') ?? 1) == 2 ? ThemeMode.dark : ThemeMode.light;
    fontScale = p.getDouble('font') ?? 1.0;
    avatar = p.getString('avatar');
  }

  Future<void> setDark(bool v) async {
    mode = v ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt('theme', v ? 2 : 1);
  }

  Future<void> setFont(double v) async {
    fontScale = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setDouble('font', v);
  }

  Future<void> setAvatar(String path) async {
    avatar = path;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('avatar', path);
  }
}

final settings = AppSettings();