import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kGreen = Color(0xFF1FA35C);
const kDeep = Color(0xFF0B5D3B);
const kLeaf = Color(0xFFE6F6EC);

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color cardC(BuildContext c) => isDark(c) ? const Color(0xFF14261D) : Colors.white;
Color borderC(BuildContext c) => isDark(c) ? const Color(0xFF244235) : const Color(0xFFDCEBE1);
Color mutedC(BuildContext c) => isDark(c) ? Colors.white60 : Colors.black54;
Color softC(BuildContext c) => isDark(c) ? const Color(0xFF1B3327) : kLeaf;
Color onSky(BuildContext c) => Colors.white;
const skyShadow = [
  Shadow(color: Color(0xDD000000), blurRadius: 8, offset: Offset(0, 2)),
  Shadow(color: Color(0xAA000000), blurRadius: 4, offset: Offset(0, 1)),
];

// ------------------------------------------------------------ pilihan form
const categories = ['Dompet', 'Elektronik', 'Tas', 'Kunci', 'Pakaian', 'Dokumen/Kartu', 'Alat Tulis', 'Lainnya'];
const catIcons = {
  'Dompet': Icons.account_balance_wallet,
  'Elektronik': Icons.smartphone,
  'Tas': Icons.backpack,
  'Kunci': Icons.key,
  'Pakaian': Icons.checkroom,
  'Dokumen/Kartu': Icons.badge,
  'Alat Tulis': Icons.edit,
  'Lainnya': Icons.inventory_2,
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
const posList = ['Pos Gerbang Depan', 'Pos Gerbang Belakang'];

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

// ------------------------------------------------------------------ model
enum ReportType { hilang, ditemukan }

class Report {
  final String id, name, category, categoryCustom, description, secret, area, areaDetail, pos, owner;
  final ReportType type;
  final DateTime date;
  final String? photo;
  String status;
  String token;
  DateTime? tokenExp;

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
  });

  String get typeLabel => type == ReportType.hilang ? 'Hilang' : 'Ditemukan';
  String get categoryLabel => category == 'Lainnya' && categoryCustom.isNotEmpty ? categoryCustom : category;
  IconData get icon => catIcons[category] ?? Icons.inventory_2;
  bool get isPublic => status == stActive || status == stClaimed;

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type.index, 'name': name, 'category': category, 'cc': categoryCustom,
        'desc': description, 'secret': secret, 'area': area, 'ad': areaDetail, 'pos': pos,
        'owner': owner, 'date': date.toIso8601String(), 'photo': photo, 'status': status,
        'token': token, 'exp': tokenExp?.toIso8601String(),
      };

  factory Report.fromJson(Map<String, dynamic> j) => Report(
        id: j['id'],
        type: ReportType.values[j['type']],
        name: j['name'],
        category: j['category'],
        categoryCustom: j['cc'] ?? '',
        description: j['desc'],
        secret: j['secret'],
        area: j['area'],
        areaDetail: j['ad'],
        pos: j['pos'],
        owner: j['owner'],
        date: DateTime.parse(j['date']),
        photo: j['photo'],
        status: j['status'],
        token: j['token'] ?? '',
        tokenExp: j['exp'] == null ? null : DateTime.parse(j['exp']),
      );
}

class Claim {
  final String id, reportId, claimer, answer, proof;
  final String? photo;
  final DateTime date;
  String status; // Menunggu, Disetujui, Ditolak
  String token;
  DateTime? tokenExp;

  Claim({required this.id, required this.reportId, required this.claimer, required this.answer, this.proof = '', this.photo, required this.date, this.status = 'Menunggu', this.token = '', this.tokenExp});

  Map<String, dynamic> toJson() => {
        'id': id, 'rid': reportId, 'claimer': claimer, 'answer': answer, 'proof': proof, 'photo': photo,
        'date': date.toIso8601String(), 'status': status, 'token': token, 'exp': tokenExp?.toIso8601String(),
      };

  factory Claim.fromJson(Map<String, dynamic> j) => Claim(
        id: j['id'],
        reportId: j['rid'],
        claimer: j['claimer'],
        answer: j['answer'],
        proof: j['proof'] ?? '',
        photo: j['photo'],
        date: DateTime.parse(j['date']),
        status: j['status'],
        token: j['token'] ?? '',
        tokenExp: j['exp'] == null ? null : DateTime.parse(j['exp']),
      );
}

class AppNotif {
  final String id, owner, type, title, message;
  final DateTime time;
  bool read;
  final String? reportId;
  final List<String> matchIds;
  final List<double> scores;

  AppNotif({required this.id, required this.owner, required this.type, required this.title, required this.message, required this.time, this.read = false, this.reportId, this.matchIds = const [], this.scores = const []});

  Map<String, dynamic> toJson() => {
        'id': id, 'owner': owner, 'type': type, 'title': title, 'message': message, 'time': time.toIso8601String(),
        'read': read, 'rid': reportId, 'mids': matchIds, 'scores': scores,
      };

  factory AppNotif.fromJson(Map<String, dynamic> j) => AppNotif(
        id: j['id'],
        owner: j['owner'],
        type: j['type'],
        title: j['title'],
        message: j['message'],
        time: DateTime.parse(j['time']),
        read: j['read'] ?? false,
        reportId: j['rid'],
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

/// Skor kemiripan 0..1 antara laporan hilang dan laporan temuan.
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

// ------------------------------------------------------------------ store
class Store extends ChangeNotifier {
  String email = '';
  bool guard = false;
  String guardPos = posList[0];
  List<Report> reports = [];
  List<Claim> claims = [];
  List<AppNotif> notifs = [];
  AppNotif? lastNotif;
  int _r = 1100, _c = 1000;
  final _rnd = Random.secure();

  String get name {
    if (guard) return 'Bapak Ahmad';
    final raw = email.split('@').first.replaceAll(RegExp(r'[._\-\d]+'), ' ').trim();
    if (raw.isEmpty) return 'Warga UNESA';
    return raw.split(' ').where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
  }

  String nextReportId() => 'CF-${_r++}';
  String nextClaimId() => 'CL-${_c++}';

  // -------------------------------------------------- simpan / muat
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('cf_data_v3');
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _r = j['r'];
        _c = j['c'];
        reports = (j['reports'] as List).map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
        claims = (j['claims'] as List).map((e) => Claim.fromJson(e as Map<String, dynamic>)).toList();
        notifs = (j['notifs'] as List).map((e) => AppNotif.fromJson(e as Map<String, dynamic>)).toList();
        return;
      } catch (_) {}
    }
    _seed();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cf_data_v3', jsonEncode({
      'r': _r,
      'c': _c,
      'reports': reports.map((e) => e.toJson()).toList(),
      'claims': claims.map((e) => e.toJson()).toList(),
      'notifs': notifs.map((e) => e.toJson()).toList(),
    }));
  }

  void _seed() {
    DateTime ago(int d) => DateTime.now().subtract(Duration(days: d));
    Report mk(String id, ReportType t, String name, String cat, String desc, String secret, String area, String detail, String pos, String owner, int d, {String cc = ''}) =>
        Report(id: id, type: t, name: name, category: cat, categoryCustom: cc, description: desc, secret: secret, area: area, areaDetail: detail, pos: pos, owner: owner, date: ago(d));
    reports = [
      mk('CF-1001', ReportType.ditemukan, 'Dompet Hitam', 'Dompet', 'Dompet kulit hitam, ada kartu mahasiswa', 'Ada foto kucing di slot kartu paling depan', 'Perpustakaan', 'Meja baca lantai 2', posList[0], 'budi@mhs.unesa.ac.id', 0),
      mk('CF-1002', ReportType.hilang, 'HP Samsung A54', 'Elektronik', 'Samsung A54 casing biru tua', 'Wallpaper foto pantai dan retak kecil di pojok kiri atas', 'Gedung Fakultas', 'Selasar lantai 1', posList[0], 'sari@mhs.unesa.ac.id', 1),
      mk('CF-1003', ReportType.ditemukan, 'Tas Ransel Hitam', 'Tas', 'Ransel hitam dengan gantungan boneka kecil', 'Di dalam ada buku catatan sampul hijau', 'Kantin', 'Bangku dekat kasir', posList[1], 'dedi@unesa.ac.id', 3),
      mk('CF-1004', ReportType.hilang, 'Botol Minum Biru', 'Lainnya', 'Botol minum biru tua stainless', 'Ada stiker coklat di bawah botol', 'Ruang Kelas / Laboratorium', 'Lab Komputer 2', posList[1], 'rina@mhs.unesa.ac.id', 4, cc: 'Botol minum'),
      mk('CF-1005', ReportType.ditemukan, 'Kunci Motor Honda', 'Kunci', 'Kunci Honda gantungan karet merah', 'Gantungan bertuliskan ARYA', 'Area Parkir', 'Parkiran timur dekat pos', posList[1], 'agus@unesa.ac.id', 6),
      mk('CF-1006', ReportType.ditemukan, 'Botol Minum Biru', 'Lainnya', 'Botol minum biru stainless', 'Stiker coklat kecil di dasar botol', 'Masjid / Mushola', 'Rak sepatu', posList[0], 'yusuf@mhs.unesa.ac.id', 1, cc: 'Botol minum'),
      mk('CF-1007', ReportType.hilang, 'Jaket Hijau', 'Pakaian', 'Jaket hijau army ukuran L', 'Ada tambalan bendera kecil di lengan kiri', 'Gedung Rektorat', 'Lobi', posList[0], 'wulan@mhs.unesa.ac.id', 2),
      mk('CF-1008', ReportType.ditemukan, 'Kartu Mahasiswa', 'Dokumen/Kartu', 'KTM warna biru', 'Ada goresan di sudut kanan bawah kartu', 'Gerbang / Jalan Kampus', 'Dekat halte', posList[0], 'hendra@unesa.ac.id', 0),
    ];
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

  static const tokenLife = Duration(minutes: 2);

  // Pos QR token (QR Barcode yang ditampilkan di HP Satpam)
  String posToken = '';
  DateTime? posTokenExp;
  String posTokenPos = '';

  void issuePosToken(String pos) {
    posToken = _newToken();
    posTokenExp = DateTime.now().add(tokenLife);
    posTokenPos = pos;
    _save();
    notifyListeners();
  }

  bool isPosTokenValid(String pos, String token) {
    return posToken.isNotEmpty &&
        posToken == token &&
        (posTokenPos.isEmpty || posTokenPos == pos) &&
        posTokenExp != null &&
        DateTime.now().isBefore(posTokenExp!);
  }

  void issueReportToken(Report r) {
    r.token = _newToken();
    r.tokenExp = DateTime.now().add(tokenLife);
    _save();
  }

  void issueClaimToken(Claim c) {
    c.token = _newToken();
    c.tokenExp = DateTime.now().add(tokenLife);
    _save();
  }

  bool tokenOk(String expected, String given, DateTime? exp) => expected.isNotEmpty && expected == given && exp != null && DateTime.now().isBefore(exp);

  /// Mengurai isi QR (CF|R|id|token), (CF|POS|posName|token), atau kode manual.
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

  /// Verifikasi laporan/klaim ketika pelapor/pengklaim memindai QR Pos Satpam
  String? verifyByPosToken(String kind, String targetId, String posName, String token) {
    if (!isPosTokenValid(posName, token)) {
      return 'QR Pos Satpam tidak valid atau sudah kedaluwarsa. Minta Satpam memperbarui QR Pos.';
    }

    if (kind == 'R') {
      final r = find(targetId);
      if (r == null) return 'Laporan tidak ditemukan.';
      if (r.status != stWait) return 'Laporan ini sudah diproses (${r.status}).';
      if (r.pos != posName) return 'Laporan ini harus diverifikasi di ${r.pos}, bukan di $posName.';

      // Berhasil verifikasi!
      approveReport(r);
      // LANGSUNG ganti QR Pos Satpam ke token baru (sekali pakai!)
      issuePosToken(posName);
      return null;
    } else {
      final c = findClaim(targetId);
      if (c == null) return 'Klaim tidak ditemukan.';
      if (c.status != 'Menunggu') return 'Klaim ini sudah diproses (${c.status}).';
      final r = find(c.reportId);
      if (r != null && r.pos != posName) return 'Klaim ini harus diverifikasi di ${r.pos}, bukan di $posName.';

      // Berhasil verifikasi!
      approveClaim(c);
      // LANGSUNG ganti QR Pos Satpam ke token baru (sekali pakai!)
      issuePosToken(posName);
      return null;
    }
  }

  // ----------------------------------------------------------- laporan
  void add(Report r) {
    reports.insert(0, r);
    _save();
    notifyListeners();
  }

  void approveReport(Report r) {
    r.status = stActive;
    r.token = '';
    r.tokenExp = null;
    notify(r.owner, 'verified', 'Laporan terverifikasi & diunggah', 'Laporan "${r.name}" sudah dipindai dan disetujui satpam (${r.pos}). Sekarang laporanmu tampil di Beranda.', reportId: r.id);
    runMatching(r);
    _save();
    notifyListeners();
  }

  void rejectReport(Report r) {
    r.status = stRejected;
    r.token = '';
    r.tokenExp = null;
    notify(r.owner, 'info', 'Laporan ditolak', 'Laporan "${r.name}" tidak disetujui satpam. Silakan buat laporan baru dengan data yang benar.', reportId: r.id);
    _save();
    notifyListeners();
  }

  void complete(Report r) {
    r.status = stDone;
    _save();
    notifyListeners();
  }

  // ------------------------------------------------------------- klaim
  void addClaim(Claim c) {
    claims.insert(0, c);
    final r = find(c.reportId);
    if (r != null) {
      r.status = stClaimed;
      notify(r.owner, 'claim', 'Ada klaim pada barang temuanmu', 'Seseorang mengajukan klaim untuk "${r.name}". Satpam akan memverifikasinya.', reportId: r.id);
    }
    _save();
    notifyListeners();
  }

  void approveClaim(Claim c) {
    final r = find(c.reportId);
    c.status = 'Disetujui';
    c.token = '';
    c.tokenExp = null;
    for (final o in claims.where((x) => x.reportId == c.reportId && x.id != c.id && x.status == 'Menunggu')) {
      o.status = 'Ditolak';
      notify(o.claimer, 'claim', 'Klaim tidak disetujui', 'Barang "${r?.name ?? ''}" sudah diserahkan kepada pemilik lain yang terverifikasi.', reportId: c.reportId);
    }
    if (r != null) {
      r.status = stDone;
      notify(r.owner, 'info', 'Barang temuanmu sudah diserahkan', '"${r.name}" sudah diserahkan kepada pemilik yang terverifikasi. Terima kasih!', reportId: r.id);
    }
    notify(c.claimer, 'claim', 'Klaim disetujui!', 'Klaim "${r?.name ?? ''}" disetujui satpam. Barang diserahkan di ${r?.pos ?? 'pos satpam'}.', reportId: c.reportId);
    _save();
    notifyListeners();
  }

  void rejectClaim(Claim c) {
    final r = find(c.reportId);
    c.status = 'Ditolak';
    c.token = '';
    c.tokenExp = null;
    if (r != null && !claims.any((x) => x.reportId == r.id && x.status == 'Menunggu')) r.status = stActive;
    notify(c.claimer, 'claim', 'Klaim ditolak', 'Detail rahasia pada klaim "${r?.name ?? ''}" tidak cocok dengan laporan. Kamu bisa mencoba lagi dengan data yang benar.', reportId: c.reportId);
    _save();
    notifyListeners();
  }

  // ------------------------------------------------------- notifikasi
  void notify(String owner, String type, String title, String message, {String? reportId, List<String> matchIds = const [], List<double> scores = const []}) {
    final n = AppNotif(id: '${DateTime.now().microsecondsSinceEpoch}$type', owner: owner, type: type, title: title, message: message, time: DateTime.now(), reportId: reportId, matchIds: matchIds, scores: scores);
    notifs.insert(0, n);
    lastNotif = n;
    _save();
    notifyListeners();
  }

  int unread(String who) => notifs.where((n) => n.owner == who && !n.read).length;

  void markRead(AppNotif n) {
    if (n.read) return;
    n.read = true;
    _save();
    notifyListeners();
  }

  void markAllRead(String who) {
    for (final n in notifs.where((n) => n.owner == who)) {
      n.read = true;
    }
    _save();
    notifyListeners();
  }

  /// Dipanggil setelah satpam menyetujui sebuah laporan.
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
        notify(r.owner, 'match', 'Kemungkinan barangmu ditemukan!', '${top.length} barang temuan mirip dengan "${r.name}" (kecocokan tertinggi ${(top.first.$2 * 100).round()}%). Ketuk untuk melihat.',
            reportId: r.id, matchIds: top.map((e) => e.$1.id).toList(), scores: top.map((e) => e.$2).toList());
      }
    } else {
      for (final l in reports.where((x) => x.type == ReportType.hilang && x.isPublic).toList()) {
        final s = matchScore(l, r);
        if (s >= matchThreshold) {
          notify(l.owner, 'match', 'Ada barang temuan yang mirip!', '"${r.name}" baru saja ditemukan dan cocok ${(s * 100).round()}% dengan laporan hilangmu "${l.name}". Ketuk untuk melihat.',
              reportId: l.id, matchIds: [r.id], scores: [s]);
        }
      }
    }
  }

  void logout() {
    email = '';
    guard = false;
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
